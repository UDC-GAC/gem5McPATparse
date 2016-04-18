#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

void copy(char const *source, char const *dest)
{
    int childExitStatus;
    pid_t pid;
    int status;
    char const *error_msg = "Error copying template! Quitting...\n";
    if (!source || !dest) {
        /* handle as you wish */
    }

    pid = fork();

    if (pid == 0) { /* child */
        execl("/bin/cp", "/bin/cp", source, dest, (char *)0);
    }
    else if (pid < 0) {
        /* error - couldn't start process */
        printf("%s", error_msg);
	exit(-1);
    }
    else {
        /* parent - wait for child - this has all error handling, you
         * could just call wait() as long as you are only expecting to
         * have one child process at a time.
         */
        pid_t ws = waitpid( pid, &childExitStatus, WNOHANG);
        if (ws == -1)
        { /* error */
	    printf("%s", error_msg);
	    exit(-1);
        }

        if( WIFEXITED(childExitStatus)) /* exit code in childExitStatus */
        {
            status = WEXITSTATUS(childExitStatus); /* zero is normal exit */
        }
        else if (WIFSIGNALED(childExitStatus)) /* killed */
        {
        }
        else if (WIFSTOPPED(childExitStatus)) /* stopped */
        {
        }
    }
}
