# 2.4GHz 微带天线项目

本项目使用 MATLAB 完成 2.4GHz 微带贴片天线的设计、解析估算和全波验证，并自动输出方向图、S11 和 VSWR 结果。

## 项目文件

- `design_24g_microstrip_antenna.m`
  基于 Antenna Toolbox 设计 2.4GHz 微带贴片天线，并输出几何图、方向图、S11 和 VSWR 结果。

- `analytical_24g_microstrip_design.m`
  使用传输线模型对天线尺寸、馈电点和方向图进行解析估算。

- `fullwave_24g_microstrip_validation.m`
  进行更接近实际电磁计算的全波验证，并输出结果图和摘要数据。

- `main.m`
  统一入口脚本，默认依次运行以上三个流程。

## 运行方法

1. 打开 MATLAB，并切换到本项目目录。
2. 运行 `main.m`。
3. 结果会自动保存到以下目录：
   - `results/`
   - `results_analytical/`
   - `results_fullwave/`

## 输出内容

- 天线几何图
- 3D 方向图
- 方位面和俯仰面方向图
- S11 与 VSWR 曲线
- 结果摘要文本
- MAT 数据文件

## 运行环境

- MATLAB
- Antenna Toolbox

## 说明

如果你的 MATLAB 版本不支持脚本中使用的部分 Antenna Toolbox 接口，请升级到较新的版本。