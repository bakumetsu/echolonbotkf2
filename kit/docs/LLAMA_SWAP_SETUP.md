# llama-swap setup (Windows, step by step)

**What it is:** llama-swap is a small program that sits in front of your llama.cpp. The kit sends every request to one address (`http://127.0.0.1:8080/v1`) and names a model: `swift` for code and debugging, `ap` for docs. llama-swap starts that model with your settings, and unloads the other one first, so you never have to run the .bat menu by hand.

You already have llama.cpp and both models, so this takes about 10 minutes.

## 1. Download llama-swap

1. Open https://github.com/mostlygeek/llama-swap/releases and take the newest release.
2. Under **Assets**, download the `windows_amd64` zip.
3. Unzip `llama-swap.exe` into `D:\LLM Storage\llama.cpp` (next to `llama-server.exe`).

## 2. Add the config

Copy `kit/docs/llama-swap.config.yaml` from this repo to `D:\LLM Storage\llama.cpp\config.yaml`.

It already has your model paths and your .bat flags. Edit it only if you move a model.

## 3. Start it

Close the .bat server first if it is running, since both want port 8080. Then open **PowerShell** and run:

```powershell
cd "D:\LLM Storage\llama.cpp"
.\llama-swap.exe --config config.yaml --listen 127.0.0.1:8080
```

Leave this window open while the kit runs. Press Ctrl+C to stop everything and free the GPU.

## 4. Check it works

In a second PowerShell window, from the repo folder:

```powershell
python kit\tools\backend_check.py
```

It should list `swift` and `ap`, then get a reply from each one. The first call to each model is slow (it loads ~12 GB), and the later calls are fast. You can also open http://127.0.0.1:8080/ in a browser to see llama-swap's status page and logs.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `backend_check` says connection refused | llama-swap isn't running: redo step 3. |
| `address already in use` | The .bat server is still running on 8080. Close it. |
| A model fails to load | Check the llama-swap window or the status page log. If the path looks mangled, change the forward slashes in `config.yaml` back to `\\` (double backslashes). |
| Out of memory | Lower `-c 32768` to `-c 24576` for that model. |

You can still use your .bat for chatting. Just don't run it at the same time as llama-swap.

The kit reads the address from `backend.endpoint` in `kit/workspace.json`, and which model plays which role from `backend.roles`.
