# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a monorepo for the **Nex** web framework with these main components:

- `framework/` - Core framework package (`nex_core`) published to Hex.pm
- `installer/` - Project generator package (`nex_new`) published as a Mix archive
- `website/` - Official documentation website (built with Nex itself)
- `examples/` - Example projects demonstrating framework features

# 原则1
每次对框架代码的修改，都要记录到changelog中，方便后续做框架版本发布

我会给你指令说到了升级版本的时候，你根据changelog来判断是否需要升级版本，如果需要升级版本，就升级版本号，然后更新changelog

# 原则2

如果在创建示例项目的时候，如website或者examples中的，你判断需要我们修改框架的代码才能支持，那么你要跟我说，我来评估。