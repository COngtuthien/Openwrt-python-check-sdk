#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>

#define LOG_PATH "/tmp/python_ver.log"

static void trim_newline(char *s)
{
    size_t len = strlen(s);

    while (len > 0 && (s[len - 1] == '\n' || s[len - 1] == '\r')) {
        s[len - 1] = '\0';
        len--;
    }
}

static void write_log(const char *message)
{
    FILE *log_file = fopen(LOG_PATH, "w");

    if (log_file == NULL) {
        perror("Error opening log file");
        return;
    }

    fprintf(log_file, "%s\n", message);
    fclose(log_file);
}

int main(void)
{
    int status;
    FILE *fp;
    char output[256] = {0};
    char log_message[512] = {0};
    const char *version;

    /*
     * Case 1: Python 3.9 exists.
     * Case 2: Python 3.9 does not exist.
     */
    status = system("command -v python3.9 >/dev/null 2>&1");

    if (status == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        snprintf(log_message, sizeof(log_message), "Error: Python 3.9 not found");
        fprintf(stderr, "%s\n", log_message);
        write_log(log_message);
        return 1;
    }

    fp = popen("python3.9 --version 2>&1", "r");

    if (fp == NULL) {
        snprintf(log_message, sizeof(log_message), "Error: Failed to execute python3.9 --version");
        fprintf(stderr, "%s\n", log_message);
        write_log(log_message);
        return 1;
    }

    if (fgets(output, sizeof(output), fp) == NULL) {
        pclose(fp);
        snprintf(log_message, sizeof(log_message), "Error: Failed to read Python version");
        fprintf(stderr, "%s\n", log_message);
        write_log(log_message);
        return 1;
    }

    status = pclose(fp);
    trim_newline(output);

    if (status == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        snprintf(log_message, sizeof(log_message), "Error: Failed to read Python version");
        fprintf(stderr, "%s\n", log_message);
        write_log(log_message);
        return 1;
    }

    if (strncmp(output, "Python 3.9.", 11) != 0) {
        snprintf(log_message, sizeof(log_message),
                 "Error: Python 3.9 not found. Current version: %s",
                 output);
        fprintf(stderr, "%s\n", log_message);
        write_log(log_message);
        return 1;
    }

    version = output;

    if (strncmp(version, "Python ", 7) == 0) {
        version += 7;
    }

    snprintf(log_message, sizeof(log_message),
             "Detected Python Version: %s", version);

    printf("%s\n", log_message);
    write_log(log_message);

    printf("Log saved to: %s\n", LOG_PATH);

    return 0;
}
