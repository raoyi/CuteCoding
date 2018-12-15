#include <stdio.h>
#include <windows.h>
int main(int argc,char** argv)
{
  int t, arg;
  if(argc==1)
    {
        printf("This tool pause CLI for some seconds.\nUsage:\nToolName.exe [SecondsNumber]\nPress Ctrl+C or Enter to exit.");
        getchar();
        exit(0);
    }
  sscanf(argv[1], "%d", &t);
  while(t>0)
  {
    printf("waiting %d s    \r",t);
    Sleep(1000);  //pause 1 second
    t--;
  }
  printf("\n");
  return 0;
}
