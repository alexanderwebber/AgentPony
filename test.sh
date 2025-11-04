#!/bin/bash

# Parametric analysis of AgentPony with different actor counts (powers of 2)
# Usage: ./analyze.sh [grid_size] [iterations] [max_power]

GRID_SIZE=${1:-256}
ITERATIONS=${2:-30}
MAX_POWER=${3:-16}  # Will test up to 2^MAX_POWER actors
OUTPUT_FILE="actor_analysis_${GRID_SIZE}x${GRID_SIZE}.txt"

echo "Analyzing AgentPony performance with different actor counts"
echo "Grid: ${GRID_SIZE}x${GRID_SIZE}, Iterations: ${ITERATIONS}"
echo "Testing actor counts: 1, 16, 64, 256, 1024, ... (2^0, 2^4, 2^6, 2^8, ...)"
echo "Results will be saved to: ${OUTPUT_FILE}"
echo ""

# Clear/create output file with header
echo "Actors,Power,WallTime(s),CPUUtil,Instructions,Cycles,IPC,ContextSwitches,L1MissRate(%)" > "${OUTPUT_FILE}"

# Test powers of 2, skipping odd powers (except 2^0)
for i in $(seq 0 ${MAX_POWER}); do
    # Skip odd powers except 2^0 (1 actor)
    if [ $i -ne 0 ] && [ $((i % 2)) -eq 1 ]; then
        continue
    fi
    
    # Calculate 2^i using bit shift
    ACTORS=$((1 << i))
    
    echo "Testing with ${ACTORS} actors (2^${i})..."
    
    # Run perf stat and capture output
    perf stat -o perf_temp.txt ./AgentPony ${GRID_SIZE} ${ITERATIONS} ${ACTORS} --noblock 2>&1
    
    # Parse the perf output
    WALL_TIME=$(grep "seconds time elapsed" perf_temp.txt | awk '{print $1}')
    CPU_UTIL=$(grep "CPUs utilized" perf_temp.txt | awk '{print $5}')
    INSTRUCTIONS=$(grep "instructions" perf_temp.txt | grep -v "stalled" | awk '{print $1}' | tr -d ',')
    CYCLES=$(grep "cycles" perf_temp.txt | grep -v "stalled" | awk '{print $1}' | tr -d ',')
    IPC=$(grep "insn per cycle" perf_temp.txt | head -1 | awk '{print $4}')
    CTX_SWITCHES=$(grep "context-switches" perf_temp.txt | awk '{print $1}' | tr -d ',')
    L1_MISS=$(grep "L1-dcache-load-misses" perf_temp.txt | awk '{print $4}' | tr -d '%')
    
    # Append to CSV
    echo "${ACTORS},${i},${WALL_TIME},${CPU_UTIL},${INSTRUCTIONS},${CYCLES},${IPC},${CTX_SWITCHES},${L1_MISS}" >> "${OUTPUT_FILE}"
    
    echo "  Wall time: ${WALL_TIME}s, CPU: ${CPU_UTIL}, IPC: ${IPC}, L1 miss: ${L1_MISS}%"
    echo ""
done

# Clean up
rm -f perf_temp.txt

echo "Analysis complete! Results in ${OUTPUT_FILE}"
echo ""
echo "Quick summary (sorted by wall time):"
echo "Actors     | Power | Wall Time | CPU Util | IPC  | L1 Miss%"
echo "-----------|-------|-----------|----------|------|----------"
tail -n +2 "${OUTPUT_FILE}" | sort -t',' -k3 -n | awk -F',' '{printf "%-10s | 2^%-3s | %9s | %8s | %4s | %s%%\n", $1, $2, $3, $4, $6, $9}'

echo ""
echo "Best performance:"
tail -n +2 "${OUTPUT_FILE}" | sort -t',' -k3 -n | head -1 | awk -F',' '{print "  "$1" actors (2^"$2"): "$3" seconds"}'