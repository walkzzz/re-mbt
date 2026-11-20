// re-mbt 在线演示：调用编译到 JavaScript 的同一份 MoonBit 正则实现。
// match / find_len 均来自 playground/playground.js（moon build --target js）。

import { re_match, re_find_len } from "./playground.js";

const $ = (sel) => document.querySelector(sel);

const PRESETS = {
  date: {
    pattern: "(\\d{4})-(\\d{2})-(\\d{2})",
    input: "order-2024-12-25",
  },
  word: {
    pattern: "\\w+",
    input: "hello world from moonbit",
  },
  email: {
    pattern: "[a-z]+@[a-z]+\\.[a-z]{2,3}",
    input: "contact: dev@moonbitlang.com",
  },
  redos: {
    pattern: "(a+)+$",
    input: "a".repeat(200000) + "!",
  },
};

function setOut(id, text) {
  $(id).textContent = text;
}

function run(presetName) {
  const preset = presetName ? PRESETS[presetName] : null;
  if (preset) {
    $("#pattern").value = preset.pattern;
    $("#input").value = preset.input;
  }
  const pattern = $("#pattern").value;
  const input = $("#input").value;

  const started = performance.now();
  let matched = false;
  let len = -1;
  let error = null;
  try {
    matched = re_match(pattern, input);
    len = re_find_len(pattern, input);
  } catch (e) {
    error = e;
  }
  const elapsed = performance.now() - started;

  if (error) {
    setOut("#out", "调用失败：" + error.message);
    return;
  }

  if (!pattern || pattern.length === 0) {
    setOut("#out", "请输入模式（空模式在 MoonBit 中按编译错误处理）");
    return;
  }

  const lines = [
    `pattern = ${pattern}`,
    `input   = ${input.length > 80 ? input.slice(0, 60) + "…（共 " + input.length + " 字符）" : input}`,
    `matched = ${matched}`,
    `match length = ${len < 0 ? "—（无匹配/非法模式）" : len}`,
    `elapsed = ${elapsed.toFixed(2)} ms（编译 + 匹配，含一次性 JIT 预热）`,
  ];
  if (presetName === "redos") {
    lines.push("");
    lines.push(
      matched
        ? "✅ 回溯引擎通常在此崩溃/超时；re-mbt 的惰性 DFA 每个字节只推进一次状态。"
        : "✅ 未匹配（末尾 '!' 阻止匹配），耗时与输入长度线性相关。",
    );
  }
  setOut("#out", lines.join("\n"));
  if (matched && presetName === "redos") {
    setOut("#perf", `20 万字符单次匹配 ${elapsed.toFixed(2)} ms（线性时间，无回溯重试）`);
  }
}

document.querySelectorAll("button[data-run]").forEach((button) => {
  button.addEventListener("click", () => run());
});
document.querySelectorAll("button[data-preset]").forEach((button) => {
  button.addEventListener("click", () => run(button.dataset.preset));
});

setOut("#out", "引擎已加载（JavaScript / MoonBit 同源实现）：点击「匹配」或选择预置示例。");
setOut("#perf", "点击「ReDoS 压力」运行 20 万字符压测。");