#!/bin/bash
# ============================================
# Random test file generator for sync testing
# Total dataset size = 50GB
# QNAP BusyBox compatible with background jobs
# ============================================

base="/share/derf_sync_test/TestData"
mkdir -p "$base"

# === Configuration ===
target_size_gb=50
target_size_bytes=$((target_size_gb * 1024 * 1024 * 1024))  # 50GB in bytes
folders=10
files_per_folder=100
total_files=$((folders * files_per_folder))
parallel_jobs=4           # Max background jobs

avg_file_size=$((target_size_bytes / total_files))
bytes_created=0

echo "Target total size: $target_size_gb GB (~$((target_size_bytes / 1024 / 1024)) MB)"
echo "Creating $folders folders with $files_per_folder files each..."
echo

for i in $(seq 1 $folders); do
    folder="$base/folder_$i"
    mkdir -p "$folder"
    echo ">> Folder $i/$folders: $folder"

    job_count=0

    for j in $(seq 1 $files_per_folder); do
        # ±10% variation
        variation=$((avg_file_size / 10))
        rand_variation=$(( (RANDOM % (2 * variation + 1)) - variation ))
        size_bytes=$((avg_file_size + rand_variation))

        # Ensure we don't exceed target
        remaining_bytes=$((target_size_bytes - bytes_created))
        if [ $size_bytes -gt $remaining_bytes ]; then
            size_bytes=$remaining_bytes
        fi

        (
            head -c $size_bytes /dev/urandom > "$folder/file_${j}.bin"
            echo -n "."
        ) &

        job_count=$((job_count + 1))
        bytes_created=$((bytes_created + size_bytes))

        # Limit background jobs
        if [ $job_count -ge $parallel_jobs ]; then
            wait
            job_count=0
        fi

        # Stop if target reached
        if [ $bytes_created -ge $target_size_bytes ]; then
            wait
            echo
            echo "✅ Target size reached: $bytes_created bytes (~$target_size_gb GB)"
            exit 0
        fi
    done

    wait  # Ensure folder jobs finish
    echo " done."
done

echo
echo "✅ Dataset creation complete!"
echo "Total bytes created: $bytes_created"
find "$base" -type f | wc -l | awk '{print "Total files created:", $1}'
du -sh "$base"

