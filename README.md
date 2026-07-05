# Quick Start：3D IC Partition 学生项目

你的任务是实现一个 Partition 程序，把 testcase 中的每个 standard cell 分配到 `Top` 或 `Bottom`。本项目提供后续 Placement、Terminal Insertion 和 Evaluator，可以直接验证划分并查看最终 HPWL。

## 1. 环境要求

- Linux x86-64；
- Bash；
- 参考 partition 使用 32 位 `shmetis`，系统需要支持 32 位 Linux 运行库。

进入发布目录：

```bash
cd contest_release
chmod +x partition partition_checker placement placer terminal_stage evaluator shmetis
chmod +x run.sh
```

## 2. 先运行参考流程

```bash
./run.sh testcases/case1.txt results/reference_case1
```

运行顺序：

```text
reference partition
→ partition_checker
→ placement
→ terminal_stage
→ evaluator
```

生成三个文件：

```text
results/reference_case1.part     Partition 结果
results/reference_case1.place    Placement 结果
results/reference_case1.out      最终答案
```

正常情况下会看到：

```text
Partition check: PASS
Top die utilization: PASS
Bottom die utilization: PASS
Total HPWL for this design is 130
```

## 3. 实现自己的 Partition

学生程序必须支持：

```bash
./student_partition <testcase.txt> <result.part>
```

输出格式：

```text
NumInstances 3
Inst C1 Top
Inst C2 Bottom
Inst C3 Top
```

基本要求：

- 每个 instance 恰好出现一次；
- instance 名称必须来自 testcase；
- 层名称只能是 `Top` 或 `Bottom`；
- Top 和 Bottom 都不能超过最大利用率。

完整语法见 [STAGE_FORMATS.md](STAGE_FORMATS.md)。

## 4. 运行学生程序和参考后端

假设你的程序是当前目录下的 `student_partition`：

```bash
PARTITION=./student_partition \
./run.sh \
    testcases/case1.txt \
    results/student_case1
```

脚本会自动：

1. 运行你的 Partition；
2. 运行 Placement；
3. 插入跨层 terminal；
4. 调用 evaluator 计算最终 HPWL。

替换其他阶段使用相同方式：

```bash
PARTITION=./my_partition \
PLACEMENT=./my_placement \
TERMINAL=./my_terminal \
EVALUATOR=./my_evaluator \
./run.sh testcases/case1.txt results/my_case1
```

四个变量都可以省略；省略时使用发布包内的参考程序。

## 5. 只检查 Partition

调试时可以只运行前两步：

```bash
./student_partition testcases/case1.txt results/student_case1.part

./partition_checker \
    testcases/case1.txt \
    results/student_case1.part
```

合法输出示例：

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

checker 返回值：

```text
0  合法
1  文件格式、分配或利用率不合法
2  命令行参数错误
```

## 6. 分阶段运行

从已有 Partition 开始布局：

```bash
./placement \
    testcases/case1.txt \
    results/student_case1.part \
    results/student_case1.place
```

从已有 Placement 开始插入 terminal：

```bash
./terminal_stage \
    testcases/case1.txt \
    results/student_case1.place \
    results/student_case1.out
```

评测最终答案：

```bash
./evaluator \
    testcases/case1.txt \
    results/student_case1.out
```

## 7. 优化目标

首先保证 partition 合法，然后尝试：

1. 减少 `Cut nets`；
2. 降低最终 `Total HPWL`；
3. 缩短 Partition 运行时间。

同一种 cell 在 Top 和 Bottom technology 下的面积可能不同，移动 cell 时必须使用目标 die 对应的面积。

## 8. 包内文件

```text
partition              参考 Partition
shmetis                参考 Partition 的内部依赖
partition_checker      Partition 检查器
placement              Placement 阶段
placer                 Placement 内部引擎
terminal_stage         Terminal Insertion 阶段
evaluator              最终评测器
visualize              独立 SVG 布局可视化程序
run.sh                 四阶段流水线；默认参考程序，可替换任意阶段
testcases/              测试用例
examples/               示例输出
STAGE_FORMATS.md        完整接口与文件格式
```

## 9. 常见问题

### `Partition check: FAIL`

根据 checker 输出检查重复、遗漏、未知 instance、错误的层名称或利用率超标。

### `shmetis: No such file or directory`

通常是系统缺少 32 位运行库。该问题只影响参考 partition，不影响学生自行编译的 64 位 partition。

### Placement 输出很多日志

这是参考 placer 的正常迭代信息。最终以 evaluator 的合法性结果和 HPWL 为准。

## 10. 生成布局图

完整流程产生 `.out` 文件后，可以生成 PNG：

```bash
./visualize \
    testcases/case1.txt \
    results/case1.out \
    results/case1.png
```

PNG 包含三个并排视图：Top Die、Bottom Die 和 Terminal。所有 standard cell 使用相同的蓝色，红色矩形表示 terminal。
