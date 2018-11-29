defmodule PathMatchTest do
    use ExUnit.Case

    describe "match" do
        test "exact" do
            glob = "a/b/c.txt"
            assert PathMatch.match?(glob, "a/b/c.txt")
            refute PathMatch.match?(glob, "/a/b/c.txt")
            refute PathMatch.match?(glob, "A/b/c.txt")
            refute PathMatch.match?(glob, "a/b/c.txT")
            refute PathMatch.match?(glob, "a/b/c.png")
            refute PathMatch.match?(glob, "b/c.txt")
            refute PathMatch.match?(glob, "c.txt")

            assert PathMatch.match?("/a/b/c.txt", "/a/b/c.txt")
            assert PathMatch.match?("A/b/c.txt", "A/b/c.txt")
            assert PathMatch.match?("a/b/c.txT", "a/b/c.txT")
            assert PathMatch.match?("a/b/c.png", "a/b/c.png")
            assert PathMatch.match?("b/c.txt", "b/c.txt")
            assert PathMatch.match?("c.txt", "c.txt")
        end

        test "'**' wildcard" do
            path = "a/b/c.txt"
            assert PathMatch.match?("**/c.txt", path)
            assert PathMatch.match?("**/b/c.txt", path)
            assert PathMatch.match?("**/a/b/c.txt", path)
            assert PathMatch.match?("**/a/**/c.txt", path)
            refute PathMatch.match?("**/.txt", path)
            refute PathMatch.match?("**/a/c.txt", path)
            refute PathMatch.match?("**.txt", path)
            assert PathMatch.match?("**/*/b/c.txt", path)
            assert PathMatch.match?("**/*/c.txt", path)
        end

        test "'*' wildcard" do
            path = "a/b/c.txt"
            assert PathMatch.match?("*/*/c.txt", path)
            assert PathMatch.match?("*/b/c.txt", path)
            assert PathMatch.match?("a/*/c.txt", path)
            assert PathMatch.match?("a/b/*", path)
            assert PathMatch.match?("a/b/*.txt", path)
            assert PathMatch.match?("a/b/c.t*t", path)
            assert PathMatch.match?("a/b/c.*", path)
            assert PathMatch.match?("a/b/c.txt*", path)
            assert PathMatch.match?("*a*/*b*/*c*.*t*x*t*", path)
            refute PathMatch.match?("*/a/b/c.txt", path)
            refute PathMatch.match?("a/*/*/c.txt", path)
            refute PathMatch.match?("*/c.txt", path)
            refute PathMatch.match?("a/b/*.png", path)
        end

        test "'?' wildcard" do
            path = "a/b/c.txt"
            assert PathMatch.match?("?/?/c.txt", path)
            assert PathMatch.match?("?/b/c.txt", path)
            assert PathMatch.match?("a/?/c.txt", path)
            refute PathMatch.match?("a/b/?", path)
            assert PathMatch.match?("a/b/?.txt", path)
            assert PathMatch.match?("a/b/c.t?t", path)
            refute PathMatch.match?("a/b/c.?", path)
            refute PathMatch.match?("a/b/c.txt?", path)
            refute PathMatch.match?("?a?/?b?/?c?.?t?x?t?", path)
            refute PathMatch.match?("?/a/b/c.txt", path)
            refute PathMatch.match?("a/?/?/c.txt", path)
            refute PathMatch.match?("?/c.txt", path)
            refute PathMatch.match?("a/b/?.png", path)
        end

        test "alternation" do
            path = "a/b/c.txt"
            assert PathMatch.match?("{a,b,c}/{a,b,c}/c.txt", path)
            assert PathMatch.match?("{a,b,c}/b/c.txt", path)
            assert PathMatch.match?("{l,k,j,h,g,f,d,s,a}/b/c.txt", path)
            assert PathMatch.match?("a/b/{c.txt}", path)
            assert PathMatch.match?("a/b/{c.txt,c.png}", path)
            refute PathMatch.match?("a/{b/c.txt}", path)
            assert PathMatch.match?("a/{b/c.txt}", "a/{b/c.txt}")
            refute PathMatch.match?("{b,c}/b/c.txt", path)
            refute PathMatch.match?("{a,b,c}/{a,bb,c}/c.txt", path)
            assert PathMatch.match?("a/b/c.{}txt", path)
            refute PathMatch.match?("c.{txt", "c.txt")
            assert PathMatch.match?("c.{txt", "c.{txt")
        end

        test "character" do
            path = "a/b/c.txt"
            assert PathMatch.match?("[abc]/[a-c]/c.txt", path)
            assert PathMatch.match?("[a-c]/b/c.txt", path)
            assert PathMatch.match?("[lkjhgfdsa]/b/c.txt", path)
            refute PathMatch.match?("a/b/[c.txt]", path)
            refute PathMatch.match?("a[/]b/c.txt", path)
            assert PathMatch.match?("a[/]b/c.txt", "a[/]b/c.txt")
            refute PathMatch.match?("[bc]/b/c.txt", path)
            refute PathMatch.match?("[!a]/b/c.txt", path)
            assert PathMatch.match?("[!b]/[!c]/[!a].txt", path)
            refute PathMatch.match?("c.[txt", "c.txt")
            assert PathMatch.match?("c.[txt", "c.[txt")
            assert PathMatch.match?("[0-9a-z]", "4")
            assert PathMatch.match?("[0-9a-z]", "g")
            refute PathMatch.match?("[!0-9a-z]", "4")
            refute PathMatch.match?("[!0-9a-z]", "g")
            assert PathMatch.match?("[!0-9a-z]", "G")
        end
    end
end
