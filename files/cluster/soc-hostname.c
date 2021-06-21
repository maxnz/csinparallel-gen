#include <unistd.h>

int main(int argc, char **argv, char **envp) {
  execve("/usr/bin/hostname", argv, envp);
}
