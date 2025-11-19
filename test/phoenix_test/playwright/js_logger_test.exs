defmodule PhoenixTest.Playwright.JsLoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias PhoenixTest.Playwright.JsLogger

  describe "log/3" do
    test "succeeds on unknown message structure" do
      msg = %{a: 1}
      assert capture_log(fn -> JsLogger.log(:error, "Hi", msg) end) =~ "Hi"
    end

    test "adds complete file location" do
      msg =
        log_msg(
          location: %{
            url: "http://localhost:4002/assets/app.js",
            line_number: 7085,
            column_number: 10
          }
        )

      assert capture_log(fn -> JsLogger.log(:error, "Hi", msg) end) =~
               "Hi (http://localhost:4002/assets/app.js:7085)"
    end

    test "adds file not found" do
      msg =
        log_msg(
          location: %{
            url: "http://localhost:4002/file.css",
            line_number: 0,
            column_number: 0
          }
        )

      assert capture_log(fn -> JsLogger.log(:error, "Hi", msg) end) =~ "Hi (http://localhost:4002/file.css)"
    end

    test "ignores line number 0" do
      msg =
        log_msg(
          location: %{
            url: "http://localhost:4002/assets/app.js",
            line_number: 0
          }
        )

      assert capture_log(fn -> JsLogger.log(:error, "Hi", msg) end) =~ "Hi (http://localhost:4002/assets/app.js)"
    end

    test "handles missing line number" do
      msg = log_msg(location: %{url: "http://localhost:4002/assets/app.js"})
      assert capture_log(fn -> JsLogger.log(:error, "Hi", msg) end) =~ "Hi (http://localhost:4002/assets/app.js)"
    end

    test "handles blank url" do
      msg = log_msg(location: %{url: ""})
      assert capture_log(fn -> JsLogger.log(:error, "Hi", msg) end) =~ "Hi"
    end
  end

  defp log_msg(params) do
    %{
      params:
        Enum.into(params, %{
          args: [%{guid: "handle@2ae9bdee66c01d900097b961352f69f4"}],
          type: "error",
          location: %{
            url: "http://localhost:4002/assets/app.js",
            line_number: 7085,
            column_number: 10
          },
          text: "hello world",
          page: %{guid: "page@47f9839e9773e11062e7794049ae830c"}
        }),
      method: :console,
      guid: "browser-context@6cb68e0f88cb4d3de5f56d4d91de65da"
    }
  end
end
