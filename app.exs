#!/usr/bin/env elixir
# app.exs — System Monitor HTTP Service in Elixir (no Mix project needed)

Mix.install([
  {:plug_cowboy, "~> 2.0"},
  {:jason, "~> 1.4"}
])

Application.ensure_all_started(:os_mon)

defmodule Sysmon.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/health" do
    send_resp(conn, 200, "ok")
  end

  get "/metrics" do
    metrics = %{
      cpu_percent: cpu_usage(),
      memory_used_mb: memory_usage(),
      disk_used_pct: disk_usage("/")
    }

    json = Jason.encode!(metrics)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

# –– VULNERABLE FIX READ ENDPOINT ––
get "/read" do
  requested = conn.params["file"] || ""
  base      = Path.expand("priv/data", File.cwd!())
  full      = Path.expand(requested, File.cwd!())

  if String.starts_with?(full, base) do
    contents = File.read!(full)
    send_resp(conn, 200, contents)
  else
    send_resp(conn, 400, "Invalid file path")
  end
end

  #–– Helpers ––#

  defp cpu_usage do
    {idle1, total1} = read_cpu()
    Process.sleep(100)
    {idle2, total2} = read_cpu()
    dt = total2 - total1
    di = idle2 - idle1
    usage = if dt > 0, do: (dt - di) * 100.0 / dt, else: 0.0
    Float.round(usage, 1)
  end

  defp read_cpu do
    [first_line | _] = File.read!("/proc/stat") |> String.split("\n")
    [_cpu | fields] = String.split(first_line, ~r/\s+/, trim: true)
    ints = Enum.map(fields, &String.to_integer/1)
    idle = Enum.at(ints, 3) + Enum.at(ints, 4)
    total = Enum.sum(ints)
    {idle, total}
  end

  defp memory_usage do
    info = File.read!("/proc/meminfo")
           |> String.split("\n")
           |> Enum.map(fn l -> String.split(l, ~r/:\s*/, parts: 2) end)
           |> Enum.into(%{}, fn [k, v] -> {k, String.to_integer(String.replace(v, ~r/\s+kB/, ""))} end)

    used_kb = info["MemTotal"] - info["MemAvailable"]
    Float.round(used_kb / 1024.0, 1)
  end

  defp disk_usage(path) do
    {out, 0} = System.cmd("df", ["-Pk", path])
    out
    |> String.split("\n")
    |> Enum.at(1)
    |> String.split(~r/\s+/, trim: true)
    |> Enum.at(4)
    |> String.trim_trailing("%")
    |> String.to_integer()
  end
end

# Start HTTP server
{:ok, _} = Plug.Cowboy.http(Sysmon.Router, [], port: 4000)
IO.puts("🚀 Server running at http://localhost:4000")
:timer.sleep(:infinity)
