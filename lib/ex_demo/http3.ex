defmodule ExDemo.Http3 do
  require Logger

  def start(port \\ 8080) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Start http server 3 on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket, data \\ nil) do
    case read_req(socket) do
      {:req_line, _method, target, _protocol_version} ->
        with path <- File.cwd!() <> "/priv" <> target,
             {:ok, data} <- File.read(path) do
          serve(socket, data)
        else
          _ ->
            serve(socket)
        end
      {:req_header, _header_field, _header_value} ->
        serve(socket, data)
      {:req_end} ->
        send_res(socket, data)
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

  defp send_res(socket, nil) do
    msg = "Not Found"
    res_msg =
      """
      HTTP/1.1 404 Not Found
      Content-Length: #{String.length(msg)}

      #{msg}
      """
    
    :gen_tcp.send(socket, res_msg)
    :gen_tcp.close(socket)
  end

  defp send_res(socket, data) do
    res_msg =
      """
      HTTP/1.1 200 OK
      Content-Length: #{String.length(data)}

      #{data}
      """
    
    :gen_tcp.send(socket, res_msg)
    :gen_tcp.close(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end
end