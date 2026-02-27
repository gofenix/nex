defmodule Nex.MixTasksTest do
  use ExUnit.Case, async: true

  describe "Mix.Tasks.Nex.Dev" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Mix.Tasks.Nex.Dev)
    end

    test "has shortdoc defined" do
      shortdoc = Mix.Task.shortdoc(Mix.Tasks.Nex.Dev)
      assert is_binary(shortdoc)
      assert shortdoc =~ "dev"
    end

    test "parses port option correctly" do
      {opts, _, _} =
        OptionParser.parse(["--port", "8080"], switches: [port: :integer, host: :string])

      assert opts[:port] == 8080
    end

    test "parses host option correctly" do
      {opts, _, _} =
        OptionParser.parse(["--host", "0.0.0.0"], switches: [port: :integer, host: :string])

      assert opts[:host] == "0.0.0.0"
    end

    test "parses multiple options correctly" do
      {opts, _, _} =
        OptionParser.parse(["--port", "3000", "--host", "localhost"],
          switches: [port: :integer, host: :string]
        )

      assert opts[:port] == 3000
      assert opts[:host] == "localhost"
    end
  end

  describe "Mix.Tasks.Nex.Start" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Mix.Tasks.Nex.Start)
    end

    test "has shortdoc defined" do
      shortdoc = Mix.Task.shortdoc(Mix.Tasks.Nex.Start)
      assert is_binary(shortdoc)
      assert shortdoc =~ "production"
    end

    test "parses port option correctly" do
      {opts, _, _} =
        OptionParser.parse(["--port", "9000"], switches: [port: :integer, host: :string])

      assert opts[:port] == 9000
    end

    test "parses host option correctly" do
      {opts, _, _} =
        OptionParser.parse(["--host", "192.168.1.1"], switches: [port: :integer, host: :string])

      assert opts[:host] == "192.168.1.1"
    end
  end

  describe "task behavior verification" do
    test "Nex.Dev has correct shortdoc" do
      dev_shortdoc = Mix.Task.shortdoc(Mix.Tasks.Nex.Dev)
      assert dev_shortdoc == "Start Nex development server"
    end

    test "Nex.Start has correct shortdoc" do
      start_shortdoc = Mix.Task.shortdoc(Mix.Tasks.Nex.Start)
      assert start_shortdoc == "Start Nex production server"
    end
  end
end
