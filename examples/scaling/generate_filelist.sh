#!/bin/bash
# Generates a --filelist input of arbitrary size for exercising/benchmarking
# the MPI dynamic task distribution (see MPI=ON in the top-level README) at
# scale, by cycling through the receptor/ligand pairs already bundled under
# input/. The docking chemistry is repeated/uninteresting; this is purely
# about generating enough independent jobs to distribute across many ranks.
#
# Usage: ./generate_filelist.sh <num_jobs> [output_file]

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

num_jobs="${1:?Usage: $0 <num_jobs> [output_file]}"
output_file="${2:-$script_dir/filelist_${num_jobs}.txt}"

if ! [[ "$num_jobs" =~ ^[0-9]+$ ]] || [ "$num_jobs" -lt 1 ]; then
	echo "Error: <num_jobs> must be a positive integer (got '$num_jobs')" >&2
	exit 1
fi

# Receptor/ligand pairs bundled under input/, all with matching *_protein.maps.fld
# and *_ligand.pdbqt files.
pdbs=(1ac8 1stp 3ce3 3tmn 7cpa)
num_pdbs=${#pdbs[@]}

: > "$output_file"
for ((i = 0; i < num_jobs; i++)); do
	pdb="${pdbs[$((i % num_pdbs))]}"
	printf '%s\n' \
		"input/${pdb}/derived/${pdb}_protein.maps.fld" \
		"input/${pdb}/derived/${pdb}_ligand.pdbqt" \
		"$(printf 'scale_job_%06d_%s' "$i" "$pdb")" \
		>> "$output_file"
done

echo "Wrote $num_jobs jobs to $output_file"
echo "Run from $repo_root with, e.g.:"
echo "  mpirun -np <workers+1> ./bin/autodock_gpu_mpi_64wi --filelist $output_file --nrun 10"
