pragma Singleton

import QtQuick
import Quickshell

// Text matching for the launcher (accent- and case-insensitive).
Singleton {
    id: root

    function normalize(text: string): string {
        return (text ?? "").toLowerCase().replace(/œ/g, "oe").replace(/æ/g, "ae").replace(/ß/g, "ss").normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    }

    function isBoundary(text: string, index: int): bool {
        return index === 0 || /[\s\-_.\/:|]/.test(text[index - 1]);
    }

    // How well one normalized word matches a normalized text. 0 = no match.
    // `fuzzy` also accepts the word's letters in order with gaps (e.g. "ffx"
    // for "firefox"), for short fields like names only.
    function scoreWord(word: string, text: string, fuzzy: bool): real {
        if (!word)
            return 1;
        if (!text)
            return 0;
        if (text === word)
            return 100;
        if (text.startsWith(word))
            return 85;
        const index = text.indexOf(word);
        if (index > 0)
            return isBoundary(text, index) ? 70 : 50;

        if (!fuzzy || word.length < 2)
            return 0;

        // Subsequence: every char in order; rewards runs and word starts.
        // Matches spread too widely are noise, not intent.
        let first = -1;
        let from = 0;
        let points = 0;
        let run = 0;
        for (const ch of word) {
            const found = text.indexOf(ch, from);
            if (found < 0)
                return 0;
            if (first < 0)
                first = found;
            run = found === from ? run + 1 : 0;
            points += 1 + run + (isBoundary(text, found) ? 2 : 0);
            from = found + 1;
        }
        if (from - first > word.length * 3)
            return 0;
        return 10 + 30 * Math.min(1, points / (word.length * 3));
    }

    // Matches a normalized query against fields: [[text, weight, fuzzy], ...].
    // Every word of the query must match some field; the score is their mean.
    function match(query: string, fields: var): real {
        const words = query.split(/\s+/).filter(w => w.length > 0);
        if (words.length === 0)
            return 1;
        let total = 0;
        for (const word of words) {
            let best = 0;
            for (const [text, weight, fuzzy] of fields)
                best = Math.max(best, scoreWord(word, text, fuzzy ?? false) * weight);
            if (best <= 0)
                return 0;
            total += best;
        }
        return total / words.length;
    }
}
