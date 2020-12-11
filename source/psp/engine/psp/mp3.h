// additional stuff for PSP mp3 decoder implementation

extern "C" int mp3_init(void);
extern "C" void mp3_deinit(void);
extern "C" int mp3_start_play(char *fname, int pos);

extern "C" int mp3_job_started;

int mp3_volume;
