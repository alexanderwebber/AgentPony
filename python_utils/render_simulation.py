import os
import re
import shutil
import sys
import numpy as np
import matplotlib.pyplot as plt
import ffmpeg

FRAME_DIR   = "temp_frames"
OUTPUT_FILE = "game_of_life_animation.mp4"
FRAME_RATE  = 2

def parse_simulation_file(filepath):
    print(f"Parsing {filepath}...")
    grids = []

    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Input file not found at {filepath}")
        return []

    chunks = re.split(r"epoch_\d+:", content)
    
    for i, chunk in enumerate(chunks):            
        grid              = []
        lines             = chunk.strip().split('\n')
        
        for line in lines:
            clean_line = line.strip()

            if not clean_line:
                continue
            
            row = [int(cell) for cell in clean_line.split()]

            if row:
                grid.append(row)

            grids.append(np.array(grid, dtype=np.uint8))
            
    return grids

def create_frames(grids, frame_dir):
    print(f"Creating frames in {frame_dir}...")
    os.makedirs(frame_dir, exist_ok=True)
    
    DPI                   = 100.0
    BASE_CELL_SIZE_INCHES = 20 / DPI
    
    for i, grid in enumerate(grids):
        frame_path    = os.path.join(frame_dir, f"frame_{i:04d}.png")
        height, width = grid.shape
        
        fig_width     = width * BASE_CELL_SIZE_INCHES + 1.0 
        fig_height    = height * BASE_CELL_SIZE_INCHES + 1.5
        
        plt.figure(figsize=(fig_width, fig_height), dpi=DPI)
        
        plt.imshow(grid, cmap='gray_r', interpolation='nearest')
        
        plt.title(f"Epoch {i} (Grid: {width}x{height})")
        plt.xticks([])
        plt.yticks([])
        
        plt.savefig(frame_path, bbox_inches='tight', pad_inches=0.1)
        plt.close()

    print(f"Created {len(grids)} frames.")

def create_video_with_library(frame_dir, output_file, frame_rate):
    print("Creating video with ffmpeg-python library...")
    input_pattern = os.path.join(frame_dir, "frame_%04d.png")

    try:
        (
            ffmpeg
            .input(input_pattern, framerate=frame_rate)
            .filter('scale', 'trunc(iw/2)*2', 'trunc(ih/2)*2') 
            .output(output_file, vcodec='libx264', pix_fmt='yuv420p') 
            .overwrite_output()  # This is the '-y' flag
            .run(capture_stdout=True, capture_stderr=True) # Executes the command
        )
        print(f"\nSuccessfully created video: {output_file}")
        
    except ffmpeg.Error as e:
        # This catches errors from the ffmpeg executable
        print("\n--- ERROR ---")
        print("ffmpeg-python failed to create the video.")
        # Decode stderr from bytes to string to make it readable
        print("FFmpeg stderr:", e.stderr.decode()) 
        print("--------------")
    except FileNotFoundError:
        # This catches the error if the ffmpeg executable itself isn't found
        print("\n--- ERROR ---")
        print("ffmpeg command not found. Please make sure ffmpeg is installed")
        print("and available in your system's PATH. (The library needs it too!)")
        print("--------------")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

def main():
    if len(sys.argv) < 2:
        print("Error: No input file provided.")
        print(f"Usage: python {sys.argv[0]} <input_file_path>")
        sys.exit(1)
        
    input_file = sys.argv[1]
    
    try:
        grids = parse_simulation_file(input_file)
        
        if not grids:
            print("No valid grids were parsed. Exiting.")
            return

        create_frames(grids, FRAME_DIR)
        
        create_video_with_library(FRAME_DIR, OUTPUT_FILE, FRAME_RATE)
        
    finally:
        if os.path.exists(FRAME_DIR):
            print(f"Cleaning up {FRAME_DIR}...")
            shutil.rmtree(FRAME_DIR)
            print("Cleanup complete.")

if __name__ == "__main__":
    main()
