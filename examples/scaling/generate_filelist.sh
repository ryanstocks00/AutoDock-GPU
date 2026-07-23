#!/bin/bash
# Generates a --filelist input of arbitrary size for exercising/benchmarking
# the MPI dynamic task distribution (see MPI=ON in the top-level README) at
# scale, by cycling through the receptor/ligand pairs already bundled under
# input/. This is purely about generating enough independent jobs to
# distribute across many ranks, but the five test systems do span a real
# range of ligand complexity (0-17 rotatable bonds), so job runtimes vary
# rather than being N copies of one easy or one hard case:
#
#   PDB   Atoms  Rot.bonds  Target -> ligand
#   1ac8    8       0       Engineered protein cavity (C-H...O bond study) -> 3,4,5-trimethylthiazole
#   1stp   18       5       Streptavidin -> biotin
#   3ce3   37       5       c-Met tyrosine kinase domain -> pyrrolopyridinepyridone-based inhibitor
#   3tmn   27       1       Thermolysin (zinc metalloprotease) -> Val-Trp (hydrolysis product)
#   7cpa   43      17       Carboxypeptidase A (zinc metalloprotease) -> phosphonate inhibitor
#
# See RCSB (rcsb.org/structure/<PDB>) for each structure's full details.
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
