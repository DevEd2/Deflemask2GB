/*
SongInserter.c 
by Dalton Messmer (messmerd)

Copies gbs song data into base ROM. 

Usage: 
    SongInserter [output.gb] [song.gbs] (uses default base ROM) 
    SongInserter [output.gb] [song.gbs] [base_rom.gb]
*/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h> 

#define DEFAULT_BASE_ROM "rom.gb" 

#define GBS_SONG_START 0x70
#define GBS_SONG_NAME 0x10 
#define GBS_SONG_AUTHOR 0x30 

#define ROM_SONG_START 0x500 
#define ROM_GRAPHICS_DATA_START 0x7C000 
#define ROM_SONG_NAME 0x7C715 
#define ROM_SONG_AUTHOR 0x7C729 

int main(int argc, char *argv[]) 
{   
    FILE *fout, *fin, *fbase; 

    if (argc < 3 || argc > 4) 
    {
        // Display usage info 
        printf("Usage:\n");
        printf("SongInserter [output.gb] [song.gbs] (uses default base ROM)\n"); 
        printf("SongInserter [output.gb] [song.gbs] [base_rom.gb]\n"); 
        return 0; 
    }
    else  
    {
        printf("Starting...\n");

        // Open files 
        if (argc == 4) 
        {
            fbase = fopen(argv[3], "rb");
        }
        else
        {
            fbase = fopen(DEFAULT_BASE_ROM, "rb");
        }
        
        fin = fopen(argv[2], "rb");
        fout = fopen(argv[1], "wb");

        if (fbase == NULL) 
        {
            printf("ERROR: Failed to open base ROM '%s'\n", argc == 4 ? argv[3] : DEFAULT_BASE_ROM); 
            return 1; 
        } 
        if (fin == NULL) 
        {
            printf("ERROR: Failed to open gbs file '%s'\n", argv[2]); 
            return 1; 
        }
        if (fout == NULL) 
        {
            printf("ERROR: Failed to open output file '%s'\n", argv[1]); 
            return 1; 
        }

        // Read base rom and copy its contents into a buffer  
        fseek(fbase, 0, SEEK_END);
        long fsize_rom = ftell(fbase);
        fseek(fbase, 0, SEEK_SET); 

        unsigned char *rom = (unsigned char *)malloc(fsize_rom * sizeof(unsigned char));
        fread(rom, 1, fsize_rom, fbase);
        fclose(fbase);

        // Write song data to rom buffer 
        printf("Writing song data\n");
        fseek(fin, 0, SEEK_END);
        long song_data_size = ftell(fin);
        if (song_data_size > ROM_GRAPHICS_DATA_START - ROM_SONG_START) 
        {
            printf("ERROR: Cannot insert song without overwriting graphics data.\n"); 
            free(rom);
            return 1; 
        }

        fseek(fin, GBS_SONG_START, SEEK_SET); 
        fread(&(rom[ROM_SONG_START]), 1, song_data_size, fin); 

        // Write song name to rom buffer 
        printf("Writing song name\n");
        fseek(fin, GBS_SONG_NAME, SEEK_SET); 
        for (int i = 0; i < 18; i++) 
        {
            unsigned char c = toupper(fgetc(fin));
            rom[ROM_SONG_NAME + i] = c == 0 ? ' ' : c;
        }

        // Write song author to rom buffer 
        printf("Writing song author\n");
        fseek(fin, GBS_SONG_AUTHOR, SEEK_SET); 
        for (int i = 0; i < 18; i++) 
        {
            unsigned char c = toupper(fgetc(fin));
            rom[ROM_SONG_AUTHOR + i] = c == 0 ? ' ' : c;
        } 

        // Write rom buffer to output file and close files 
        printf("Writing buffer to ROM\n");
        fwrite(rom, 1, fsize_rom, fout);
        
        fclose(fin); 
        fclose(fout); 

        free(rom);

        printf("Success!\n");
    }

    return 0; 
}
