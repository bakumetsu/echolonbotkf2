# llama-swap setup (Windows, step by step)

**What it is:** llama-swap is one small program that sits in front of llama.cpp. The kit sends every request to one address (`http://127.0.0.1:8080/v1`) and names a model ("coder" or "small"). llama-swap loads that model, unloading the previous one first, so your 16 GB of VRAM only ever holds one model. You never start or stop models by hand.

You do this once. It takes about 20 minutes, most of it downloading.

## 1. Make two folders

- `C:\llama` for the programs
- `C:\models` for the model files (.gguf)

## 2. Download llama.cpp (the engine)

1. Open https://github.com/ggml-org/llama.cpp/releases and take the newest release.
2. Under **Assets**, download the Windows **CUDA** zip (`llama-…-bin-win-cuda-…-x64.zip`). If a matching `cudart-…` zip is listed, download that too.
   - Your RTX 5060 Ti is a Blackwell card, so pick the build with the **highest CUDA version** offered (12.8 or newer). Older CUDA 12.4 builds may not support the card. [UNVERIFIED: check the release notes]
3. Unzip both into `C:\llama`. You should now have `C:\llama\llama-server.exe`.

## 3. Download llama-swap

1. Open https://github.com/mostlygeek/llama-swap/releases and take the newest release.
2. Download the `windows_amd64` zip and unzip it into `C:\llama`. You should now have `C:\llama\llama-swap.exe`.

## 4. Put your models in `C:\models`

- **Coder:** your 27B model as a `.gguf`. On 16 GB, pick **Q3_K_M** or **IQ3_M** (about 12-13 GB). IQ4_XS is about 15 GB, which leaves no room for context.
- **Small (optional):** an 8B model at **Q6_K** (about 6.7 GB) for quick jobs.

## 5. Write the config

1. Copy `kit/docs/llama-swap.config.yaml` from this repo to `C:\llama\config.yaml`.
2. Edit the two `-m C:\models\….gguf` lines to match your actual file names. If you only have one model, delete the `"small"` block.

## 6. Start it

Open **PowerShell** and run:

```powershell
cd C:\llama
.\llama-swap.exe --config config.yaml --listen 127.0.0.1:8080
```

Leave this window open while the kit runs. Close it, or press Ctrl+C, to stop everything and free the GPU.

## 7. Check it works

In a second PowerShell window, from the repo folder:

```powershell
python kit\tools\backend_check.py
```

This lists the models llama-swap knows about, then asks each one for a one-word reply and prints how long loading took. The first call to a model is slow because it is loading (30-90 s for 27B); later calls are fast. You can also open http://127.0.0.1:8080/ in a browser to see llama-swap's status page.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `backend_check` says connection refused | llama-swap isn't running: redo step 6. |
| A model times out or fails to load | Run its `llama-server.exe …` line from the config by hand in PowerShell (replace `${PORT}` with `9000`) to see the real error. |
| `CUDA error` / `no kernel image` | Wrong llama.cpp build for the card: get a newer CUDA build (step 2). |
| Out of memory | Lower `-c 16384` to `-c 8192`, or use a smaller quant. |
| `--flash-attn on` is rejected | Older llama.cpp: change it to `-fa`. |

The kit reads the address from `backend.endpoint` in `kit/workspace.json`. Change it there if you use a port other than 8080.
