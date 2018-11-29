defmodule PathMatchTest do
    use ExUnit.Case

    describe "match" do
        test "exact" do
            run = fn match ->
                glob = "a/b/c.txt"
                assert match.(glob, "a/b/c.txt")
                refute match.(glob, "/a/b/c.txt")
                refute match.(glob, "A/b/c.txt")
                refute match.(glob, "a/b/c.txT")
                refute match.(glob, "a/b/c.png")
                refute match.(glob, "b/c.txt")
                refute match.(glob, "c.txt")

                assert match.("/a/b/c.txt", "/a/b/c.txt")
                assert match.("A/b/c.txt", "A/b/c.txt")
                assert match.("a/b/c.txT", "a/b/c.txT")
                assert match.("a/b/c.png", "a/b/c.png")
                assert match.("b/c.txt", "b/c.txt")
                assert match.("c.txt", "c.txt")
            end

            run.(&PathMatch.match?/2)
            run.(&PathMatch.match?(PathMatch.compile(&1), &2))
        end

        test "'**' wildcard" do
            run = fn match ->
                path = "a/b/c.txt"
                assert match.("**/c.txt", path)
                assert match.("**/b/c.txt", path)
                assert match.("**/a/b/c.txt", path)
                assert match.("**/a/**/c.txt", path)
                refute match.("**/.txt", path)
                refute match.("**/a/c.txt", path)
                refute match.("**.txt", path)
                assert match.("**/*/b/c.txt", path)
                assert match.("**/*/c.txt", path)
            end

            run.(&PathMatch.match?/2)
            run.(&PathMatch.match?(PathMatch.compile(&1), &2))
        end

        test "'*' wildcard" do
            run = fn match ->
                path = "a/b/c.txt"
                assert match.("*/*/c.txt", path)
                assert match.("*/b/c.txt", path)
                assert match.("a/*/c.txt", path)
                assert match.("a/b/*", path)
                assert match.("a/b/*.txt", path)
                assert match.("a/b/c.t*t", path)
                assert match.("a/b/c.*", path)
                assert match.("a/b/c.txt*", path)
                assert match.("*a*/*b*/*c*.*t*x*t*", path)
                refute match.("*/a/b/c.txt", path)
                refute match.("a/*/*/c.txt", path)
                refute match.("*/c.txt", path)
                refute match.("a/b/*.png", path)
            end

            run.(&PathMatch.match?/2)
            run.(&PathMatch.match?(PathMatch.compile(&1), &2))
        end

        test "'?' wildcard" do
            run = fn match ->
                path = "a/b/c.txt"
                assert match.("?/?/c.txt", path)
                assert match.("?/b/c.txt", path)
                assert match.("a/?/c.txt", path)
                refute match.("a/b/?", path)
                assert match.("a/b/?.txt", path)
                assert match.("a/b/c.t?t", path)
                refute match.("a/b/c.?", path)
                refute match.("a/b/c.txt?", path)
                refute match.("?a?/?b?/?c?.?t?x?t?", path)
                refute match.("?/a/b/c.txt", path)
                refute match.("a/?/?/c.txt", path)
                refute match.("?/c.txt", path)
                refute match.("a/b/?.png", path)
            end

            run.(&PathMatch.match?/2)
            run.(&PathMatch.match?(PathMatch.compile(&1), &2))
        end

        test "alternation" do
            run = fn match ->
                path = "a/b/c.txt"
                assert match.("{a,b,c}/{a,b,c}/c.txt", path)
                assert match.("{a,b,c}/b/c.txt", path)
                assert match.("{l,k,j,h,g,f,d,s,a}/b/c.txt", path)
                assert match.("a/b/{c.txt}", path)
                assert match.("a/b/{c.txt,c.png}", path)
                refute match.("a/{b/c.txt}", path)
                assert match.("a/{b/c.txt}", "a/{b/c.txt}")
                refute match.("{b,c}/b/c.txt", path)
                refute match.("{a,b,c}/{a,bb,c}/c.txt", path)
                assert match.("a/b/c.{}txt", path)
                refute match.("c.{txt", "c.txt")
                assert match.("c.{txt", "c.{txt")
            end

            run.(&PathMatch.match?/2)
            run.(&PathMatch.match?(PathMatch.compile(&1), &2))
        end

        test "character" do
            run = fn match ->
                path = "a/b/c.txt"
                assert match.("[abc]/[a-c]/c.txt", path)
                assert match.("[a-c]/b/c.txt", path)
                assert match.("[lkjhgfdsa]/b/c.txt", path)
                refute match.("a/b/[c.txt]", path)
                refute match.("a[/]b/c.txt", path)
                assert match.("a[/]b/c.txt", "a[/]b/c.txt")
                refute match.("[bc]/b/c.txt", path)
                refute match.("[!a]/b/c.txt", path)
                assert match.("[!b]/[!c]/[!a].txt", path)
                refute match.("c.[txt", "c.txt")
                assert match.("c.[txt", "c.[txt")
                assert match.("[0-9a-z]", "4")
                assert match.("[0-9a-z]", "g")
                refute match.("[!0-9a-z]", "4")
                refute match.("[!0-9a-z]", "g")
                assert match.("[!0-9a-z]", "G")
            end

            run.(&PathMatch.match?/2)
            run.(&PathMatch.match?(PathMatch.compile(&1), &2))
        end
    end
end
