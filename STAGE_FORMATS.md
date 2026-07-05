# 阶段接口与文件格式规范

本文档严格规定 Partition、Placement 和 Terminal Insertion 三个阶段的命令行接口与文件语法。关键字和名称均区分大小写。

```text
testcase.txt → partition → result.part
testcase.txt + result.part → placement → result.place
testcase.txt + result.place → terminal_stage → result.out
```

## 1. 通用规则

- 文件使用纯文本；
- 字段之间使用一个或多个空白字符分隔；
- instance 和 net 名称必须与 testcase 完全一致；
- 坐标为十进制整数；
- 当前格式不支持注释；
- 声明数量必须与后续记录数量一致；
- 文件末尾不允许出现未定义字段。

## 2. Partition 接口

### 2.1 命令行

```bash
./partition <testcase.txt> <result.part>
```

返回值约定：

```text
0  正常生成结果
非 0 运行失败
```

### 2.2 输出语法

```text
NumInstances <N>
Inst <instance-name> <Top|Bottom>
... 共 N 行 Inst
```

示例：

```text
NumInstances 8
Inst C1 Top
Inst C2 Top
Inst C3 Top
Inst C4 Bottom
Inst C5 Bottom
Inst C6 Bottom
Inst C7 Top
Inst C8 Top
```

约束：

- `<N>` 必须等于 testcase 中的 `NumInstances`；
- 每个 testcase instance 必须恰好出现一次；
- `Inst` 行的顺序任意；
- die 字段只能是 `Top` 或 `Bottom`；
- 两个 die 都必须满足各自的最大利用率。

Top 面积计算：

```text
TopUsedArea = Σ width(instance_type, TopTech)
                × height(instance_type, TopTech)
```

Bottom 面积计算同理。合法条件：

```text
TopUsedArea    <= DieArea × TopDieMaxUtil / 100
BottomUsedArea <= DieArea × BottomDieMaxUtil / 100
```

### 2.3 常见错误

错误的层名称：

```text
Inst C1 top
```

`top` 非法，必须写成 `Top`。

重复 instance：

```text
Inst C1 Top
Inst C1 Bottom
```

即使总行数等于 N，重复和遗漏仍然非法。

多余字段：

```text
Inst C1 Top 100
```

Partition 阶段不包含坐标。

### 2.4 Checker

```bash
./partition_checker <testcase.txt> <result.part>
```

示例输出：

```text
Partition format: PASS
Instance assignment: PASS (8/8)
Top die utilization: PASS (area 620/720, utilization 68.89%/80%)
Bottom die utilization: PASS (area 600/810, utilization 66.67%/90%)
Top instances: 5
Bottom instances: 3
Cut nets: 1
Partition check: PASS
```

## 3. Placement 接口

### 3.1 命令行

```bash
./placement <testcase.txt> <result.part> <result.place>
```

### 3.2 输出语法

```text
NumInstances <N>
Inst <instance-name> <Top|Bottom> <x> <y>
... 共 N 行 Inst
```

示例：

```text
NumInstances 4
Inst C1 Top 0 0
Inst C2 Bottom 12 15
Inst C3 Top 7 10
Inst C4 Bottom 0 0
```

语义：

- `<x> <y>` 是 cell 左下角坐标；
- 坐标使用 testcase 的原始坐标单位；
- `.place` 中的 die 必须与输入 `.part` 一致；
- 每个 instance 必须恰好出现一次；
- cell 必须位于所属 die 内；
- cell 必须对齐合法 row/site；
- 同一 die 内的 cell 不得重叠。

参考 `terminal_stage` 会检查文件语法和 instance 完整性；最终几何合法性由 evaluator 检查。

## 4. Terminal Insertion 接口

### 4.1 命令行

```bash
./terminal_stage <testcase.txt> <result.place> <result.out>
```

### 4.2 最终输出语法

```text
TopDiePlacement <NT>
Inst <top-instance-name> <x> <y>
... 共 NT 行
BottomDiePlacement <NB>
Inst <bottom-instance-name> <x> <y>
... 共 NB 行
NumTerminals <K>
Terminal <net-name> <x> <y>
... 共 K 行
```

示例：

```text
TopDiePlacement 2
Inst C1 0 0
Inst C3 7 10
BottomDiePlacement 2
Inst C2 12 15
Inst C4 0 0
NumTerminals 1
Terminal N2 14 8
```

约束：

- `NT + NB` 必须等于 testcase 中的 instance 总数；
- 每个 instance 必须恰好出现一次；
- 每条跨层网络需要一个 terminal；
- terminal 的 net 名称必须来自 testcase；
- terminal 必须位于合法区域；
- terminal 之间必须满足 testcase 中的 spacing 约束。

最终输出使用 ICCAD 2022 Problem B evaluator 所接受的格式。

## 5. 独立运行示例

### 仅运行并检查 Partition

```bash
./partition testcases/case1.txt results/case1.part
./partition_checker testcases/case1.txt results/case1.part
```

### 从已有 Partition 开始 Placement

```bash
./placement \
    testcases/case1.txt \
    results/case1.part \
    results/case1.place
```

### 从已有 Placement 开始 Terminal Insertion

```bash
./terminal_stage \
    testcases/case1.txt \
    results/case1.place \
    results/case1.out
```

### 最终评测

```bash
./evaluator testcases/case1.txt results/case1.out
```

## 6. 学生程序兼容性检查

如果只替换 Partition：

```bash
PARTITION=./student_partition \
./run.sh \
    testcases/case1.txt \
    results/student_case1
```

如果程序能够通过 `partition_checker`，并被参考 placement 和 terminal 阶段完整处理，就说明接口兼容。
