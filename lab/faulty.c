#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <syslog.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static const char *paths[] = {
    "/etc/CLUE_DO_LAB",
    "/var/lib/lab/insight",
    "/tmp/lab-fix-me"
};
#define N_PATHS (sizeof(paths)/sizeof(paths[0]))

void test_zombie_orphan(void) {
    pid_t pid;

    pid = fork();
    if (pid == 0) {
        syslog(LOG_INFO, "zombie-child[%d]: dormindo para virar zombie", getpid());
        sleep(5);
        exit(0);
    }
    syslog(LOG_INFO, "parent[%d]: criou zombie-child PID %d", getpid(), pid);

    pid = fork();
    if (pid == 0) {
        pid_t gc = fork();
        if (gc == 0) {
            syslog(LOG_INFO, "grandchild-orphan[%d]: agora sou órfão (pai saiu)", getpid());
            sleep(3);
            exit(0);
        } else if (gc > 0) {
            syslog(LOG_INFO, "child-orphan[%d]: terminando, deixo neto %d órfão", getpid(), gc);
            exit(0);
        }
    }
    waitpid(pid, NULL, 0);
}

void test_fd_leak(void) {
    pid_t pid = fork();
    if (pid == 0) {
        syslog(LOG_INFO, "leak-child[%d]: iniciando leak de FDs", getpid());
        for (int i = 0; i < 10000; i++) {
            int fd = open("/dev/null", O_RDONLY);
            if (fd < 0) {
                syslog(LOG_ERR, "leak-child[%d]: falha ao abrir FD na iteração %d", getpid(), i);
                break;
            }
            if (i % 1000 == 0)
                syslog(LOG_INFO, "leak-child[%d]: abri FD %d (iter %d)", getpid(), fd, i);
        }
        pause();
        _exit(0);
    } else if (pid > 0) {
        syslog(LOG_INFO, "parent[%d]: criado leak-child PID %d", getpid(), pid);
    }
}

void try_paths(void) {
    for (int i = 0; i < N_PATHS; i++) {
        pid_t pid = fork();
        if (pid < 0) {
            syslog(LOG_ERR, "fork() falhou para recurso #%d", i+1);
            continue;
        }
        if (pid == 0) {
            syslog(LOG_INFO, "filho[%d]: checando recurso #%d", getpid(), i+1);
            int fd = open(paths[i], O_RDONLY);
            if (fd < 0)
                syslog(LOG_WARNING, "filho[%d]: falha em recurso #%d", getpid(), i+1);
            else {
                syslog(LOG_INFO, "filho[%d]: abriu %s", getpid(), paths[i]);
                close(fd);
            }
            exit(fd >= 0 ? 0 : 1);
        } else {
            syslog(LOG_INFO, "pai[%d]: filho %d criado para recurso #%d", getpid(), pid, i+1);
            sleep(1);
            waitpid(pid, NULL, 0);
        }
    }
}

void net_test(void) {
    pid_t pid = fork();
    if (pid == 0) {
        syslog(LOG_INFO, "filho[net %d]: iniciando teste TCP", getpid());
        int sock = socket(AF_INET, SOCK_STREAM, 0);
        struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(80) };
        inet_pton(AF_INET, "93.184.216.34", &addr.sin_addr);
        if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) == 0)
            syslog(LOG_INFO, "filho[net %d]: TCP OK", getpid());
        else
            syslog(LOG_ERR, "filho[net %d]: TCP falhou", getpid());
        close(sock);

        syslog(LOG_INFO, "filho[net %d]: iniciando teste UDP", getpid());
        sock = socket(AF_INET, SOCK_DGRAM, 0);
        addr.sin_port = htons(53);
        inet_pton(AF_INET, "8.8.8.8", &addr.sin_addr);
        sendto(sock, "ping", 4, 0, (struct sockaddr*)&addr, sizeof(addr));
        syslog(LOG_INFO, "filho[net %d]: UDP enviado", getpid());
        close(sock);
        exit(0);
    } else if (pid > 0) {
        waitpid(pid, NULL, 0);
    }
}

void exec_ls(void) {
    pid_t pid = fork();
    if (pid == 0) {
        syslog(LOG_INFO, "filho[ls %d]: executando ls /", getpid());
        execlp("ls", "ls", "/", NULL);
        _exit(1);
    } else if (pid > 0) {
        waitpid(pid, NULL, 0);
    }
}

int main(void) {
    openlog("lab-solver-full", LOG_PID|LOG_CONS, LOG_USER);
    syslog(LOG_INFO, "lab-solver-full[%d]: iniciando", getpid());

    test_zombie_orphan();
    test_fd_leak();
    try_paths();

    int fd = open(paths[N_PATHS-1], O_RDONLY);
    if (fd < 0) {
        syslog(LOG_ERR, "lab-solver-full[%d]: ainda não resolvido", getpid());
        closelog();
        return 1;
    }
    close(fd);

    net_test();
    exec_ls();

    syslog(LOG_INFO, "lab-solver-full[%d]: recurso final encontrado!", getpid());
    printf("✅ Lab resolvido! Você desbloqueou: %s\n", paths[N_PATHS-1]);
    closelog();
    return 0;
}
