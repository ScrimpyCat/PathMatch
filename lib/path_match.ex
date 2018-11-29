defmodule PathMatch do
    defp match_to_regex(match, regexes \\ { "", "" }, escape \\ false, wildcard \\ nil)
    defp match_to_regex("", { literal, _ }, _, _) do
        IO.iodata_to_binary(["^", literal, "$"])
        |> Regex.compile!
    end
    defp match_to_regex("\\" <> match, regexes, false, wildcard), do: match_to_regex(match, regexes, true, wildcard)
    defp match_to_regex("[!" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "\\[!"], [special, "[^"] }, false, :character)
    defp match_to_regex("[" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "\\["], [special, "["] }, false, :character)
    defp match_to_regex("]" <> match, { _, special }, false, :character) do
        special = [special, "]"]
        match_to_regex(match, { special, special }, false, nil)
    end
    defp match_to_regex("-" <> match, { literal, special }, false, :character), do: match_to_regex(match, { [literal, "\\-"], [special, "-"] }, false, :character)
    defp match_to_regex("{" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "\\{"], [special, "("] }, false, :alternation)
    defp match_to_regex("}" <> match, { _, special }, false, :alternation) do
        special = [special, ")"]
        match_to_regex(match, { special, special }, false, nil)
    end
    defp match_to_regex("," <> match, { literal, special }, false, :alternation), do: match_to_regex(match, { [literal, ","], [special, "|"] }, false, :alternation)
    defp match_to_regex("?" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "."], [special, "."] }, false, nil)
    defp match_to_regex("*" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, ".*"], [special, ".*"] }, false, nil)
    defp match_to_regex(<<c :: utf8, match :: binary>>, { literal, special }, _, wildcard) when c in '.^$*+-?()[]{}|\\' do
        c = <<"\\", c :: utf8>>
        match_to_regex(match, { [literal, c], [special, c] }, false, wildcard)
    end
    defp match_to_regex(<<c :: utf8, match :: binary>>, { literal, special }, _, wildcard) do
        c = <<c :: utf8>>
        match_to_regex(match, { [literal, c], [special, c] }, false, wildcard)
    end

    defp path_match(path, glob, precompiled \\ false, processed \\ false)
    defp path_match([], [], _, _), do: true
    defp path_match([], ["**"], _, _), do: true
    defp path_match([], _, _, _), do: false
    defp path_match([_|path], ["**", "*"|glob], precompiled, _), do: path_match(path, ["**"|glob], precompiled, precompiled)
    defp path_match([component|path], ["**", component|glob], precompiled, _), do: path_match(path, glob, precompiled, precompiled)
    defp path_match([component|path], ["**", match = %Regex{}|glob], precompiled, _) do
        if Regex.match?(match, component) do
            path_match(path, glob, precompiled, precompiled)
        else
            path_match(path, ["**", match|glob], precompiled, true)
        end
    end
    defp path_match(path, ["**", match|glob], precompiled, false), do: path_match(path, ["**", match_to_regex(match)|glob], precompiled, true)
    defp path_match([_|path], glob = ["**"|_], precompiled, processed), do: path_match(path, glob, precompiled, processed)
    defp path_match([_|path], ["*"|glob], precompiled, _), do: path_match(path, glob, precompiled, precompiled)
    defp path_match([component|path], [component|glob], precompiled, _), do: path_match(path, glob, precompiled, precompiled)
    defp path_match([component|path], [match = %Regex{}|glob], precompiled, _) do
        if Regex.match?(match, component) do
            path_match(path, glob, precompiled, precompiled)
        else
            false
        end
    end
    defp path_match(path, [match|glob], precompiled, false), do: path_match(path, [match_to_regex(match)|glob], precompiled, true)
    defp path_match(_, _, _, _), do: false

    @doc """
      Match the given glob expression (compiled or uncompiled) against the path.
    """
    @spec match?(String.t | [String.t | Regex.t], String.t) :: boolean
    def match?(glob, path) when is_list(glob), do: path_match(Path.split(path), glob, true)
    def match?(glob, path), do: path_match(Path.split(path), Path.split(glob))

    @doc """
      Pre-compile a glob expression for faster matching.
    """
    @spec compile(String.t) :: [String.t | Regex.t]
    def compile(glob) do
        Path.split(glob)
        |> Enum.map(fn
            "**" -> "**"
            "*" -> "*"
            match -> if(Regex.match?(~r/((?<=[^\\])|^)(\*|\?|\[.*?(?<=[^\\])\]|\{.*?(?<=[^\\])\})/, match), do: match_to_regex(match), else: match)
        end)
    end
end
