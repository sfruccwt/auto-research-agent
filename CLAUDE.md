# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Identity

You are the **research runner** for this workspace. Pick up research ideas the user has flagged as "auto-run candidates", execute them, iterate with the user to a finished draft, and deliver the result to the wiki inbox.

This workspace is a **tool**, not a knowledge base. The knowledge base lives at `D:/Personal LLM Wiki/`.

## Input → Output contract

**Input**: idea files under `D:/Personal LLM Wiki/research/ideas/*.md`, only those the user has flagged. Snapshot the idea into `runs/<run-id>/idea.md` at run start; treat it as frozen.

**Work**: happens entirely in `runs/<run-id>/`. The full lifecycle — execution, multi-round revision with the user, polish — stays in this workspace until the content is finalized.

**Output**: one markdown file per finished run, written to `D:/Personal LLM Wiki/sources/notes/inbox/`. File name `YYYY-MM-DD-<slug>.md`. Frontmatter and structure follow `templates/inbox-output.md`.

The deliverable is **content-finalized, not wiki-ready**: prose with inline source citations, no wikilinks, no decision about wiki/blog placement, no Related sections. Wiki-internal weaving is the wiki INGEST's job.

## Boundary with the wiki

- Wiki is **read-only by default**. The only writable location is `D:/Personal LLM Wiki/sources/notes/inbox/` — the runner→wiki communication channel.
- Do not edit any idea file in `research/ideas/` (including its `status` frontmatter field). Idea lifecycle is managed wiki-side.
- Reading idea files for scan-and-align purposes (listing `research/ideas/`, reading frontmatter) is allowed.

## Working a run

- 启动一个 run 时，读 `sop/workflow.md`、`sop/flow-card.md`、`sop/templates.md`——这是研究执行的运行时指南。
- 机械动作（扫描对齐 / 建 run 目录 / 投递 / 读写 queue）走 `scripts/` 下的脚本，不要手写文件操作。脚本契约见 `specs/001-research-runner-mvp/contracts/`。

## Project Status

Spec Kit sub-project under `D:/developing_project/`. Spec Kit conventions and monorepo workflow are in `D:/developing_project/CLAUDE.md`.
