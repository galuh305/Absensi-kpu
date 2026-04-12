<?php

namespace App\Console\Commands;

use App\Models\AbsenLog;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class PurgeOldAbsenLogsCommand extends Command
{
    protected $signature = 'absen:purge-old-logs {--dry-run : Hanya tampilkan jumlah, tanpa menghapus}';

    protected $description = 'Hapus baris absen_logs yang tanggalnya lebih lama dari 2 tahun dari hari ini';

    public function handle(): int
    {
        $cutoff = Carbon::today()->subYears(2);

        $query = AbsenLog::query()->where('tanggal', '<', $cutoff->toDateString());
        $count = $query->count();

        if ($count === 0) {
            $this->info('Tidak ada data absensi lebih dari 2 tahun yang perlu dihapus.');

            return self::SUCCESS;
        }

        if ($this->option('dry-run')) {
            $this->warn("[dry-run] Akan menghapus {$count} baris (tanggal < {$cutoff->toDateString()}).");

            return self::SUCCESS;
        }

        $deleted = AbsenLog::query()
            ->where('tanggal', '<', $cutoff->toDateString())
            ->delete();

        $this->info("Menghapus {$deleted} baris absensi (tanggal sebelum {$cutoff->toDateString()}).");

        return self::SUCCESS;
    }
}
