defmodule MsearchTest do
  use ExUnit.Case, async: true

  import Mock

  describe "create_index/1" do
    test "should create index" do
      with_mock Meilisearch.Indexes, create: fn _, _ -> :ok end do
        assert :ok == Binoculo.Msearch.create_index("test")
      end
    end
  end

  describe "delete_index/1" do
    test "should delete index" do
      with_mock Meilisearch.Indexes, delete: fn _ -> :ok end do
        assert :ok == Binoculo.Msearch.delete_index("test")
      end
    end
  end

  describe "save/1" do
    test "should save item to index" do
      with_mock Meilisearch.Documents, add_or_replace: fn _, _ -> {:ok, "mocked_response"} end do
        assert {:ok, _response} = Binoculo.Msearch.save(%{host: "127.0.0.1", port: 21_210})
      end

      header =
        "HTTP/1.0 302 Moved Temporarily\r\nDate: Sat, 06 Jan 2024 15:55:33 GMT\r\nServer: Boa/0.93.15\r\nX-Frame-Options: SAMEORIGIN\r\nConnection: close\r\nContent-Type: text/html\r\nLocation: /admin/login.asp\r\n\r\n"

      with_mock Meilisearch.Documents, add_or_replace: fn _, _ -> {:ok, "mocked_response"} end do
        assert {:ok, _response} =
                 Binoculo.Msearch.save(%{response: header, host: "127.0.0.1", port: 80})
      end
    end

    test "should not save item to index" do
      with_mock Meilisearch.Documents,
        add_or_replace: fn _, _ -> {:error, 501, "error_mocked_response"} end do
        assert {:error, _response} = Binoculo.Msearch.save(%{host: "x.x.x.x", port: 21_210})
      end
    end
  end

  describe "search/2" do
    test "should search for item" do
      with_mock Meilisearch.Search, search: fn _, _, _ -> {:ok, "mocked_response"} end do
        assert {:ok, _response} = Binoculo.Msearch.search("apache", %{})
      end
    end
  end

  describe "search_by_id/1" do
    test "should search for item" do
      with_mock Meilisearch.Documents, get: fn _, _ -> {:ok, "mocked_response"} end do
        assert {:ok, _response} = Binoculo.Msearch.search_by_id(1)
      end
    end
  end
end
