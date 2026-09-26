#!/usr/bin/env python3
"""
make_covell_fullframe_box_v16.py — v16

What's new (vs v15c):
- Progress bars with `tqdm` for:
  * frame rendering
  * GIF assembly
  * MP4 assembly
- Timing logs for:
  * file discovery
  * OSM roads fetch/load (with version-aware bbox)
- More informative console output (counts, first N files, etc.)

Usage (same flags as v15c):
  python make_covell_fullframe_box_v16.py \
    --in /Users/savannahlicc/Desktop/Bat_Doppler_Project/Data/2025/June_2025/classified_20230823_2 \
    --out /Users/savannahlicc/Desktop/Bat_Doppler_Project/classified_20230823_2_out/movie.mp4 \
    --miles 4 --dot \
    --roads_cache roads_major.gpkg \
    --roads_color "#cccccc" --roads_lw 0.6 \
    --pattern "classified_*.tif" \
    --gif 20230823_2_two_sites_full_4mi_yolo_roads.gif \
    --mp4 20230823_try_two_sites_full_4mi_yolo_roads.mp4 --fps 4 --crf 20

Dependencies (conda-forge recommended):
  mamba install -c conda-forge python=3.11 rasterio matplotlib imageio imageio-ffmpeg geopandas osmnx shapely pyproj rtree tqdm -y
"""

import argparse, re, warnings, time
from pathlib import Path
from datetime import datetime, timezone

try:
    from zoneinfo import ZoneInfo  # Python 3.9+
except Exception:
    from backports.zoneinfo import ZoneInfo  # pip install backports.zoneinfo

import numpy as np
import rasterio
from rasterio.warp import transform, transform_bounds
from rasterio.plot import show

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MplPolygon
import matplotlib.patheffects as pe
import imageio.v2 as imageio

try:
    from tqdm.auto import tqdm
except Exception:
    def tqdm(iterable=None, **kwargs):
        # Fallback no-op if tqdm isn't available
        return iterable if iterable is not None else range(0)

# Lazy/optional heavy deps
def _try_import_osmnx():
    try:
        import osmnx as ox
        return ox
    except Exception:
        return None

def _try_import_geopandas():
    try:
        import geopandas as gpd
        return gpd
    except Exception:
        return None

# --- Site (WGS84) ---
COVELL_LAT = 38.53210169583606; COVELL_LON = -121.76159471535418

# Yolo Bypass line endpoints (WGS84)
YOLO_START_LAT = 38.564039; YOLO_START_LON = -121.638368
YOLO_END_LAT   = 38.573935; YOLO_END_LON   = -121.582394

LA_TZ = ZoneInfo("America/Los_Angeles")
STAMP_ANYWHERE = re.compile(r"(20\d{2}[01]\d[0-3]\d_[0-2]\d[0-5]\d)")

MAJOR_HIGHWAYS = [
    "motorway","trunk","primary","secondary",
    "motorway_link","trunk_link","primary_link","secondary_link"
]

def find_stamp_in_name(name: str):
    m = STAMP_ANYWHERE.search(name)
    return m.group(1) if m else None

def stamp_to_dt_utc(stamp: str):
    y = int(stamp[0:4]); mo = int(stamp[4:6]); d = int(stamp[6:8])
    hh = int(stamp[9:11]); mm = int(stamp[11:13])
    return datetime(y, mo, d, hh, mm, tzinfo=timezone.utc)

def square_ring_in_crs(lon, lat, target_crs, miles):
    half_side_m = float(miles) * 1609.344 / 2.0
    mx, my = transform("EPSG:4326", "EPSG:3857", [lon], [lat]); mx, my = mx[0], my[0]
    h = half_side_m
    ring_3857 = [(mx-h, my-h), (mx+h, my-h), (mx+h, my+h), (mx-h, my+h), (mx-h, my-h)]
    xs_3857, ys_3857 = zip(*ring_3857)
    xs, ys = transform("EPSG:3857", target_crs, list(xs_3857), list(ys_3857))
    return list(xs), list(ys)

def add_box(ax, lon, lat, crs, miles, edgecolor="red", lw=1.5):
    xs, ys = square_ring_in_crs(lon, lat, crs, miles)
    ax.add_patch(MplPolygon(list(zip(xs, ys)), fill=False, edgecolor=edgecolor, linewidth=lw, zorder=6))
    return xs, ys

def add_label_covell(ax, xs, ys, label, margin_pt=4):
    left, right = min(xs), max(xs); bottom, top = min(ys), max(ys)
    txt = ax.annotate(label, xy=(right, bottom), xycoords="data",
                      xytext=(+margin_pt, -margin_pt), textcoords="offset points",
                      ha="left", va="top", color="white", fontsize=9, fontweight="regular", zorder=7)
    txt.set_path_effects([pe.withStroke(linewidth=0.6, foreground="black")])

def add_yolo_bypass(ax, crs, color="cyan", lw=1.8, zorder=6):
    xs, ys = transform("EPSG:4326", crs, [YOLO_START_LON, YOLO_END_LON], [YOLO_START_LAT, YOLO_END_LAT])
    ax.plot(xs, ys, color=color, linewidth=lw, zorder=zorder)
    midx = (xs[0] + xs[1]) / 2.0; midy = (ys[0] + ys[1]) / 2.0
    txt = ax.annotate("Yolo Bypass", xy=(midx, midy), xycoords="data",
                      xytext=(6, -6), textcoords="offset points",
                      ha="left", va="top", color="white", fontsize=9, fontweight="regular", zorder=zorder+1)
    txt.set_path_effects([pe.withStroke(linewidth=0.6, foreground="black")])

def compute_overall_bbox_wgs84(tif_paths):
    north=-1e9; south=+1e9; east=-1e9; west=+1e9
    for p in tif_paths:
        with rasterio.open(p) as src:
            w,s,e,n = transform_bounds(src.crs, "EPSG:4326", *src.bounds, densify_pts=21)
        north=max(north,n); south=min(south,s); east=max(east,e); west=min(west,w)
    return north, south, east, west  # N,S,E,W

def _osmnx_version_tuple(ox):
    try:
        from packaging.version import Version
        v = Version(ox.__version__); return (v.major, v.minor, v.micro)
    except Exception:
        parts = ox.__version__.split(".")
        try: return tuple(int(p) for p in parts[:3])
        except Exception: return (0,0,0)

def fetch_or_load_roads(bbox_nsew, cache_path, highways=MAJOR_HIGHWAYS):
    warnings.filterwarnings("ignore", category=FutureWarning)
    gpd = _try_import_geopandas(); ox = _try_import_osmnx()
    if gpd is None or ox is None:
        print("[WARN] geopandas/osmnx not installed; skipping road overlay."); return None
    cache_path = Path(cache_path) if cache_path else None
    if cache_path and cache_path.exists():
        try:
            roads = gpd.read_file(cache_path); print(f"[INFO] Loaded roads from cache: {cache_path}"); return roads
        except Exception as e:
            print(f"[WARN] Failed to read roads cache {cache_path}: {e} — will try fetching.")

    north, south, east, west = bbox_nsew
    ver = _osmnx_version_tuple(ox)
    if ver >= (2,0,0):
        bbox = (west, south, east, north)  # (left, bottom, right, top)
    else:
        bbox = (north, south, east, west)  # legacy

    tags = {"highway": highways}
    t0 = time.perf_counter()
    try:
        print("[INFO] Fetching OSM roads…")
        roads = ox.features_from_bbox(bbox=bbox, tags=tags)
        dt = time.perf_counter() - t0
        print(f"[INFO] OSM roads fetched in {dt:.1f}s. Features: {len(roads)}")
        roads = roads[roads.geom_type.isin(["LineString","MultiLineString"])].copy()
        keep = [c for c in ["highway","name","oneway","maxspeed"] if c in roads.columns]
        roads = roads[keep+["geometry"]] if keep else roads[["geometry"]]
        roads = roads.explode(index_parts=False, ignore_index=True)
        if cache_path:
            try:
                roads.to_file(cache_path, driver="GPKG"); print(f"[INFO] Saved roads cache to: {cache_path}")
            except Exception as e: print(f"[WARN] Could not save roads cache: {e}")
        return roads
    except Exception as e:
        print(f"[WARN] OSM fetch failed: {e}"); return None

def render_frame(tif_path: Path, out_png: Path, miles: float, draw_dots: bool, lw: float, dpi: int,
                 timefmt: str, line_color: str, line_lw: float,
                 roads_gdf, roads_color, roads_lw):
    with rasterio.open(tif_path) as src:
        crs = src.crs; count = src.count
        fig, ax = plt.subplots(figsize=(8, 8))
        show(src, (1,2,3), ax=ax) if count >= 3 else show(src, 1, ax=ax)

        # Yolo Bypass
        add_yolo_bypass(ax, crs, color=line_color, lw=line_lw, zorder=6)

        # Roads
        if roads_gdf is not None:
            try:
                roads_proj = roads_gdf.to_crs(crs.to_string() if crs else "EPSG:3857")
                for geom in roads_proj.geometry:
                    try:
                        xs, ys = geom.xy
                        ax.plot(xs, ys, linewidth=roads_lw, color=roads_color, alpha=0.9, zorder=6)
                    except Exception:
                        for part in geom.geoms:
                            xs, ys = part.xy
                            ax.plot(xs, ys, linewidth=roads_lw, color=roads_color, alpha=0.9, zorder=6)
            except Exception as e:
                print(f"[WARN] Roads overlay failed for {tif_path.name}: {e}")

        # Covell overlays intentionally disabled for this variant.

        # Timestamp (if found)
        stamp = find_stamp_in_name(tif_path.name)
        if stamp:
            dt_local = stamp_to_dt_utc(stamp).astimezone(LA_TZ)
            time_str = dt_local.strftime(timefmt)
            tt = ax.text(0.99, 0.02, time_str, transform=ax.transAxes, ha="right", va="bottom",
                         color="white", fontsize=9, fontweight="regular", zorder=9)
            tt.set_path_effects([pe.withStroke(linewidth=0.6, foreground="black")])

        ax.set_title(f"{tif_path.name} — Yolo Bypass + Roads", fontsize=10)
        ax.set_xlabel("X (map units)"); ax.set_ylabel("Y (map units)")
        fig.tight_layout(); fig.savefig(out_png, dpi=dpi); plt.close(fig)

def write_gif(out_gif_path: Path, frame_paths, fps: int):
    images = []
    for fp in tqdm(frame_paths, desc="GIF: reading frames"):
        images.append(imageio.imread(fp))
    imageio.mimsave(out_gif_path, images, fps=fps, loop=0)

def write_mp4(out_mp4_path: Path, frame_paths, fps: int, crf: int):
    try:
        writer = imageio.get_writer(out_mp4_path, format="FFMPEG", mode="I",
                                    fps=fps, codec="libx264",
                                    output_params=["-pix_fmt","yuv420p","-crf",str(crf)])
        for fp in tqdm(frame_paths, desc="MP4: writing frames"):
            writer.append_data(imageio.imread(fp))
        writer.close()
    except Exception as e:
        print(f"[WARN] MP4 writing failed (missing imageio-ffmpeg?). Error: {e}")

def main():
    ap = argparse.ArgumentParser(description="Full-frame overlays: two 4-mi boxes + Yolo Bypass + OSM roads + LA local time; outputs GIF/MP4.")
    ap.add_argument("--in", dest="in_dir", required=True, help="Input folder")
    ap.add_argument("--out", dest="out_dir", required=True, help="Output folder")
    ap.add_argument("--miles", type=float, default=4.0)
    ap.add_argument("--pattern", type=str, default="classified_*.tif", help="Glob pattern")
    ap.add_argument("--dot", action="store_true")
    ap.add_argument("--lw", type=float, default=1.5)
    ap.add_argument("--dpi", type=int, default=220)
    ap.add_argument("--gif", type=str, default=None)
    ap.add_argument("--mp4", type=str, default=None)
    ap.add_argument("--fps", type=int, default=4)
    ap.add_argument("--crf", type=int, default=20)
    ap.add_argument("--timefmt", type=str, default="%a %Y-%m-%d %I:%M %p %Z")
    ap.add_argument("--line_color", type=str, default="cyan")
    ap.add_argument("--line_lw", type=float, default=1.8)
    ap.add_argument("--roads_cache", type=str, default=None)
    ap.add_argument("--roads_color", type=str, default="#cccccc")
    ap.add_argument("--roads_lw", type=float, default=0.6)
    args = ap.parse_args()

    t0 = time.perf_counter()
    in_dir = Path(args.in_dir)
    out_dir = Path(args.out_dir); out_dir.mkdir(parents=True, exist_ok=True)
    frames_dir = out_dir / "frames_full_two_boxes_yolo_roads"; frames_dir.mkdir(parents=True, exist_ok=True)

    # File discovery
    files = sorted(in_dir.glob(args.pattern)) or sorted(list(in_dir.glob("*.tif")) + list(in_dir.glob("*.tiff")))
    if not files:
        print(f"No files matched {args.pattern} (or *.tif/*.tiff) in {in_dir}"); return
    print(f"[INFO] Found {len(files)} files. First 5:", [p.name for p in files[:5]])
    print(f"[INFO] File discovery in {time.perf_counter()-t0:.2f}s")

    # Overall bbox + roads
    t1 = time.perf_counter()
    bbox_nsew = compute_overall_bbox_wgs84(files)
    roads = fetch_or_load_roads(bbox_nsew, args.roads_cache)
    print(f"[INFO] Bbox+roads step in {time.perf_counter()-t1:.2f}s")

    # Frame rendering with progress
    frame_paths = []
    for tif in tqdm(files, desc="Rendering frames"):
        out_png = frames_dir / f"{tif.stem}_two_boxes_yolo_roads_{args.miles:.2f}mi.png"
        render_frame(tif, out_png, args.miles, bool(args.dot), args.lw, args.dpi,
                     args.timefmt, args.line_color, args.line_lw,
                     roads_gdf=roads, roads_color=args.roads_color, roads_lw=args.roads_lw)
        frame_paths.append(out_png)

    # Outputs
    if args.gif and frame_paths:
        write_gif(out_dir / args.gif, frame_paths, fps=args.fps); print(f"[INFO] Wrote GIF: {out_dir / args.gif}")
    if args.mp4 and frame_paths:
        write_mp4(out_dir / args.mp4, frame_paths, fps=args.fps, crf=args.crf); print(f"[INFO] Wrote MP4: {out_dir / args.mp4}")

    print(f"[DONE] Total runtime: {time.perf_counter()-t0:.1f}s")

if __name__ == "__main__":
    main()
