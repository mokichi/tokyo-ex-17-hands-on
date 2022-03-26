defmodule ExDemo.Http2 do
  require Logger

  def start(port \\ 8080) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Start http server 2 on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket, res_data \\ %{}) do
    case read_req(socket) do
      {:req_line, method, target, protocol_version} ->
        serve(socket, Map.merge(res_data, %{method: method, target: target, protocol_version: protocol_version}))
      {:req_header, header_field, header_value} ->
        serve(socket, Map.merge(res_data, %{header_field => header_value}))
      {:req_end} ->
        send_res(socket, res_data)
    end
  end

  defp read_req(socket) do
    req_msg =
      socket
      |> read_line()
      |> String.trim()
      |> String.split(" ")

    case req_msg do
      [method, target, protocol_version] ->
        {:req_line, method, target, protocol_version}
      [header_field, header_value] ->
        {:req_header, header_field, header_value}
      _ ->
        {:req_end}
    end
  end

  defp send_res(socket, data) do
    msg = inspect(data)
    res_msg =
      """
      HTTP/1.1 200 OK
      Content-Length: #{String.length(msg)}

      #{msg}
      """
    
    :gen_tcp.send(socket, res_msg)
    :gen_tcp.close(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end
end