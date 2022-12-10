#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <ctype.h>

typedef struct {
  uint8_t bpb_jmp_instr[3];          // jmp short start
  uint8_t bpb_oem[8];                // 'MSWIN4.1'
  uint16_t bpb_bytes_per_sec;        // 512
  uint8_t bpb_sectors_per_cluster;   // 1
  uint16_t bpb_reserved_sectors;     // 1
  uint8_t bpb_fat_count;             // 2
  uint16_t bpb_dir_entries_count ;   // 0e0h
  uint16_t bpb_total_sectors;        // 2880
  uint8_t bpb_media_descriptor_type; // 0f0h
  uint16_t bpb_sectors_per_fat;      // 9
  uint16_t bpb_sectors_per_track;    // 18
  uint16_t bpb_number_of_heads;      // 2
  uint32_t bpb_number_hidden_sectors;// 0
  uint32_t bpb_large_sector_count;   // 0
  uint8_t ebr_drive_number;          // 0
  uint8_t _ebr_reserved;             // 0
  uint8_t ebr_signature;             // 29h
  uint8_t ebr_volume_id;             // 'SERI'
  uint8_t ebr_volume_label[11];      // 'RFOS       '
  uint8_t ebr_system_id[8];          // 'FAT12   '
  
  // code doesn't matter here
} __attribute__((packed)) fat12_boot_sector_t;

typedef struct {
  // Format (creation_date, last_accessed_date, last_modified_date)
  // bits 0-6   => year
  // bits 7-10  => month
  // bits 11-15 => day  
  
  // Format (creation_time, last_modified_time)
  // bits 0-4   => hours
  // bits 5-10  => minutes
  // bits 11-15 => seconds
  uint8_t filename[11];
  uint8_t attributes;
  uint8_t _reserved;
  uint8_t creation_time_tenths;
  uint16_t creation_time;
  uint16_t creation_date;
  uint16_t last_accessed_date;
  uint16_t first_cluster_high;
  uint16_t last_modified_time;
  uint16_t last_modified_date;
  uint16_t first_cluster_low;
  uint32_t file_size_bytes;
} __attribute((packed)) fat12_dir_entry_t;

fat12_boot_sector_t g_BootSector;
uint8_t* g_Fat = NULL;
fat12_dir_entry_t* g_RootDirectory = NULL;
uint32_t g_RootDirectoryEnd;

bool readBootSector(FILE* disk) {
  return fread(&g_BootSector, sizeof(g_BootSector), 1, disk) > 0;
}

bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* bufferOut) {
  bool ok = true;
  ok = ok && (fseek(disk, lba * g_BootSector.bpb_bytes_per_sec, SEEK_SET) == 0);
  ok = ok && (fread(bufferOut, g_BootSector.bpb_bytes_per_sec, count, disk) == count);
  return ok;
}

bool readFat(FILE* disk) {
  g_Fat = (uint8_t*) malloc(g_BootSector.bpb_sectors_per_fat * g_BootSector.bpb_bytes_per_sec);
  bool read_status = readSectors(disk, g_BootSector.bpb_reserved_sectors, g_BootSector.bpb_sectors_per_fat, g_Fat);
  return read_status;
}

bool readRootDirectory(FILE* disk) {
  uint32_t lba = g_BootSector.bpb_reserved_sectors + g_BootSector.bpb_sectors_per_fat * g_BootSector.bpb_fat_count;
  uint32_t size = sizeof(fat12_dir_entry_t) * g_BootSector.bpb_dir_entries_count;
  uint32_t sectors = (size / g_BootSector.bpb_bytes_per_sec);
  if (size % g_BootSector.bpb_bytes_per_sec > 0) {
    sectors++;
  }
  g_RootDirectoryEnd = lba + sectors; 
  g_RootDirectory = (fat12_dir_entry_t*) malloc(sectors * g_BootSector.bpb_bytes_per_sec);
  return readSectors(disk, lba, sectors, g_RootDirectory);
}

fat12_dir_entry_t* findFile(const char* name) {
  const int MAX_FILE_NAME = 11;
  for (uint32_t i = 0; i < g_BootSector.bpb_dir_entries_count; i++) {
    if (memcmp(name, g_RootDirectory[i].filename, MAX_FILE_NAME) == 0) {
      return &g_RootDirectory[i];
    }
  }
  return NULL;
}

bool readFile(fat12_dir_entry_t* fileEntry, FILE* disk, uint8_t* outputBuffer) {
  bool ok = true;
  uint16_t currentCluster = fileEntry->first_cluster_low;

  do {
      uint32_t lba = g_RootDirectoryEnd + (currentCluster - 2) * g_BootSector.bpb_sectors_per_cluster;
      ok = ok && readSectors(disk, lba, g_BootSector.bpb_sectors_per_cluster, outputBuffer);
      outputBuffer += g_BootSector.bpb_sectors_per_cluster * g_BootSector.bpb_bytes_per_sec;

      uint32_t fatIndex = currentCluster * 3 / 2;
      if (currentCluster % 2 == 0)
          currentCluster = (*(uint16_t*)(g_Fat + fatIndex)) & 0x0FFF;
      else
          currentCluster = (*(uint16_t*)(g_Fat + fatIndex)) >> 4;

  } while (ok && currentCluster < 0x0FF8);

  return ok;
}

int main(int argc, char** argv) {
  if (argc < 3) {
    printf("Usage: %s <disk image> <file name>\n", argv[0]);
    exit(1);
  }
  
  FILE* disk = fopen(argv[1], "r");
  if (!disk) {
    fprintf(stderr, "Failed to read file\n");
    return -1;
  }
  
  if (!readBootSector(disk)) {
    fprintf(stderr, "Could not read boot sector\n");
    return -2;
  }
  else {
    fprintf(stdout, "Successfully read boot sector\n");
  }
  
  if (!readFat(disk)) {
    fprintf(stderr, "Could not read FAT\n");
    free(g_Fat);
    return -3;
  }
  else {
    fprintf(stdout, "Successfully read FAT\n");
  }
  
  if (!readRootDirectory(disk)) {
    fprintf(stderr, "Could not read FAT\n");
    free(g_Fat);
    free(g_RootDirectory);
    return -4;
  }
  else {
    fprintf(stdout, "Successfully read root directory\n");
  }
  
  fat12_dir_entry_t* entry = findFile(argv[2]);
  if (!entry) {
    fprintf(stderr, "Could not find file, %s\n", argv[2]);
    free(g_Fat);
    free(g_RootDirectory);
    return -5;
  }
  else {
    fprintf(stdout, "Successfully found file, %s\n", argv[2]);
    fprintf(stdout, "  - filename, %s\n", entry->filename);
    fprintf(stdout, "  - filesize, %d\n", entry->file_size_bytes);
  }
  
  uint8_t* buffer = (uint8_t*) malloc(entry->file_size_bytes + g_BootSector.bpb_bytes_per_sec);
  if (!readFile(entry, disk, buffer)) {
    fprintf(stderr, "Could not read file, %s\n", argv[2]);
    free(g_Fat);
    free(g_RootDirectory);
    free(buffer);
    return -5;
  }
  else {
    fprintf(stdout, "Successfully read file, %s\n", argv[2]);
  }
  
  for (size_t i = 0; i < entry->file_size_bytes; i++) {
    if (isprint(buffer[i])) {
      fputc(buffer[i], stdout);
    }
    else {
      printf("<%02x>", buffer[i]);
    }
  }
  printf("\n");
  
  free(buffer);
  free(g_Fat);
  free(g_RootDirectory);
  return 0;
}
