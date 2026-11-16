# HW1: MapReduce & Hadoop

## Team

Fill in one row per member in your first commit (keep the repository private: this table holds your IDs).

| full name | ID number | email | GitHub username |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

Your team's repository for Homework 1, created from this template under one member's account (private, with the other members and `C0rWin` added as collaborators). The handout (hw1.pdf on Moodle) is the specification; this file
only says where things are. Creating the repository, `gh auth login`, cloning and reading CI: the guide *Getting your course
repository* on Moodle. Every member submits the repository URL in the Moodle assignment *HW1 repository link*.

| path | what |
|---|---|
| `java/` | Maven project (Java 11, Hadoop 3.4.1). `Pageview` and `Hw1` are complete; fill in the `TODO`s. |
| `python/` | Task 1 Hadoop Streaming mapper and reducer. |
| `get-data.sh` | `./get-data.sh -n` prints your team's day, hours and K; `./get-data.sh` downloads your data into `data/`. |
| `languages.tsv` | Dimension table for Task 3. |
| `report/` | Put `report.pdf` here and fill in `counters.json` from your cluster runs. |
| `logs/`, `outputs/` | Create them: job console logs and merged task outputs (see the handout). |
| `smoke/` | Smoke test: `smoke/run.sh` and the tiny sample it runs on. |

## Smoke test

Every push to `main` runs `.github/workflows/smoke.yml` (see the Actions tab). It builds the jar, runs all four
tasks with Hadoop in local mode on `smoke/sample/` and checks output formats, that Task 1 gives the same
result in Java and Python and with or without the combiner, and that `report/counters.json` is valid.
To run it yourself you need JDK 11+, Maven and Python 3 (the first run downloads Hadoop, ~500 MB, into
`~/.cache/hw1-hadoop`):

```sh
smoke/run.sh
```

No JDK or Maven? Run it in a container instead (only Docker needed; the first run downloads Hadoop into a
Docker volume):

```sh
docker run --rm -v "$PWD:/w" -w /w -v hw1-m2:/root/.m2 -v hw1-hadoop:/root/.cache/hw1-hadoop \
  maven:3.9.9-eclipse-temurin-11 bash -c 'apt-get update -qq && apt-get install -y -qq python3 >/dev/null; \
  smoke/run.sh; r=$?; chown -R '"$(id -u):$(id -g)"' java/target; exit $r'
```

Windows: run everything in the Ubuntu (WSL2) app, in your Linux home, never in PowerShell or under `/mnt/c`
(see the handout, Section 2.1).

A green run means your code runs and its output is well formed. It says nothing about correctness:
grading uses hidden data and the reference solution after the deadline.

## Submission

The last commit pushed before the deadline is graded. Commit early and often; do not commit the data
or jars (`.gitignore` covers them).
