#!/usr/bin/env bash
#
# Managing notes with fzf (https://github.com/junegunn/fzf)
# - CTRL-L: List note files in descending order by their modified time
# - CTRL-F: Search file contents
#
# Configuration:
# - $NOTE_DIR: Directory where note files are located
# - $NOTE_EXT: Note file extension (default: txt)
# https://gist.github.com/junegunn/402e3d19271bc68de59ce34eb7dc6ae5

NOTE_DIR="~/notes"
TRASH_DIR="$NOTE_DIR/trash"
EDITOR=${EDITOR:-vim}
export NOTE_EXT=${NOTE_EXT:-txt}
export NORENAME=1
cd "$NOTE_DIR"

delete() {
  echo -en "\r\x1b[KDelete $1? (y/n) "
  read yn
  if [[ "$yn" =~ ^y ]]; then
    mkdir -p "$TRASH_DIR"
    mv "$NOTE_DIR/${1}.$NOTE_EXT" "$TRASH_DIR"
  fi
}

key=ctrl-l
query="$*"
opts='--reverse --no-hscroll --no-multi --ansi --print-query --tiebreak=index'
while true; do
  if [ "$key" = ctrl-l ]; then
    out=$(
      ruby --disable=gems -x "$0" "$NOTE_DIR" list |
      fzf $opts --prompt="list> " --expect=ctrl-f,alt-d,ctrl-n --query="$query" \
        --preview 'cat {1}.$NOTE_EXT' \
        --no-clear --header=$'\nCTRL-F: find / CTRL-N: new / ALT-D: delete\n\n')
  else
    out=$(
      ruby --disable=gems -x "$0" "$NOTE_DIR" find |
      fzf $opts --prompt="find> " --expect=ctrl-l,alt-d,ctrl-n \
          --delimiter=: --nth=3.. --query="$query" \
          --preview 'bat {1}.$NOTE_EXT --color=always --decorations=never --highlight-line={2}' --preview-window 'down,+{2}/2' \
          --no-clear --header=$'\nCTRL-L: list / CTRL-N: new / ALT-D: delete\n\n')
  fi

  # 2: Error / 130: Interrupt
  (( $? % 128 == 2 )) && exit 1

  lines=$(wc -l <<< "$out")
  [ $lines -lt 2 ] && continue

  if [ "$key" = ctrl-l ]; then
    file=$(tail -1 <<< "$out" | awk 'BEGIN { FS = "\t" } { gsub(/ +$/, "", $1); print $1 }')
  else
    file=$(tail -1 <<< "$out" | awk -F: '{print $1}')
  fi

  newkey=$(head -2 <<< "$out" | tail -1)
  case "$newkey" in
    ctrl-*) key=$newkey ;;
    alt-d)  [ $lines -gt 2 ] && delete "$file" ;;
    ctrl-n)
      query=$(head -1 <<< "$out")
      [ -n "$query" ] && $EDITOR "$NOTE_DIR/${query}.$NOTE_EXT"
      ;;
    *)
      if [ "$key" = ctrl-l ]; then
        [ -n "$file" ] && $EDITOR "$NOTE_DIR/${file}.$NOTE_EXT"
      else
        # Assuming Vim
        cmd=$(tail -1 <<< "$out" |
              awk 'BEGIN { FS = ":" } { print "$EDITOR \"'$NOTE_DIR'/" $1 ".'$NOTE_EXT'\" +" $2 }')
        sh -c "$cmd"
      fi
      ;;
  esac
done

#!ruby
# encoding: utf-8

def list
  Dir[ARGV.first + '/*.' + ENV['NOTE_EXT']]
    .map { |f| { time: File.mtime(f),
                 path: f,
                 name: File.basename(f).chomp('.' + ENV['NOTE_EXT']) } }
    .sort_by { |h| [- h[:time].to_f, h[:name]] }
end

if ARGV.last == 'list'
  list.each do |h|
    puts "\x1b[1m#{h[:name].ljust(50)}\t\x1b[0;36m#{h[:time]}\x1b[m"
  end rescue exit
else
  list.each do |h|
    File.open(h[:path]).each_with_index do |line, no|
      next if line =~ /^\s*$/
      puts "\x1b[1m#{h[:name]}\x1b[m:\x1b[33m#{no + 1}\x1b[m: "
           .ljust(40) << line
    end
  end rescue exit
end
