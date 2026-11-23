"""Small from-scratch, word-level n-gram language model.

This is an educational baseline, not a reasoning model or a ChatGPT-level LLM.
It learns transition statistics only from text explicitly supplied for training.
It uses the Python standard library and no pretrained weights or external AI API.
"""
from __future__ import annotations

import json
import os
import random
import re
import tempfile
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

_TOKEN_RE = re.compile(r"\w+(?:['’]\w+)?|[^\w\s]", re.UNICODE)
_START = "<FIRA_START>"
_END = "<FIRA_END>"


class NGramLanguageModel:
    """A persistent second-order Markov language model trained from scratch."""

    def __init__(self, path: str | Path | None = None) -> None:
        default_path = Path(__file__).resolve().parent.parent / "data" / "fira_ngram_model.json"
        self.path = Path(path or os.getenv("FIRA_MODEL_PATH", str(default_path)))
        self.transitions: dict[str, Counter[str]] = defaultdict(Counter)
        self.token_count = 0
        self.training_documents = 0
        self._load()

    @staticmethod
    def tokenize(text: str) -> list[str]:
        return _TOKEN_RE.findall(text)

    @staticmethod
    def _key(first: str, second: str) -> str:
        return json.dumps([first, second], ensure_ascii=False)

    def train(self, text: str) -> dict[str, int]:
        tokens = self.tokenize(text)
        if len(tokens) < 3:
            raise ValueError("Le texte doit contenir au moins trois unités lexicales.")
        sequence = [_START, _START, *tokens, _END]
        for index in range(2, len(sequence)):
            key = self._key(sequence[index - 2], sequence[index - 1])
            self.transitions[key][sequence[index]] += 1
        self.token_count += len(tokens)
        self.training_documents += 1
        self.save()
        return {
            "new_tokens": len(tokens),
            "total_tokens": self.token_count,
            "training_documents": self.training_documents,
            "contexts": len(self.transitions),
        }

    def generate(self, seed_text: str = "", max_tokens: int = 60, seed: int | None = None) -> str:
        if not self.transitions:
            raise RuntimeError("FIRA n'a encore reçu aucun texte d'entraînement.")
        rng = random.Random(seed)
        seed_tokens = self.tokenize(seed_text)
        context = ([_START, _START] + seed_tokens)[-2:]
        output = list(seed_tokens)
        for _ in range(max_tokens):
            choices = self.transitions.get(self._key(context[0], context[1]))
            if not choices:
                choices = self.transitions.get(self._key(_START, _START))
            if not choices:
                break
            candidates = list(choices.items())
            next_token = rng.choices(
                [item[0] for item in candidates],
                weights=[item[1] for item in candidates],
                k=1,
            )[0]
            if next_token == _END:
                break
            output.append(next_token)
            context = [context[1], next_token]
        return self._detokenize(output)

    @staticmethod
    def _detokenize(tokens: Iterable[str]) -> str:
        text = ""
        no_space_before = {".", ",", ";", ":", "!", "?", ")", "]", "}"}
        no_space_after = {"(", "[", "{"}
        for token in tokens:
            if not text or token in no_space_before or text[-1:] in no_space_after:
                text += token
            else:
                text += " " + token
        return text.strip()

    def status(self) -> dict[str, int | bool | str]:
        return {
            "trained": bool(self.transitions),
            "model_type": "word-level-second-order-ngram",
            "pretrained_weights": False,
            "external_ai_api": False,
            "training_documents": self.training_documents,
            "training_tokens": self.token_count,
            "learned_contexts": len(self.transitions),
        }

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "format_version": 1,
            "model_type": "word-level-second-order-ngram",
            "token_count": self.token_count,
            "training_documents": self.training_documents,
            "transitions": {key: dict(value) for key, value in self.transitions.items()},
        }
        fd, temporary = tempfile.mkstemp(prefix="fira-model-", suffix=".tmp", dir=self.path.parent)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as stream:
                json.dump(payload, stream, ensure_ascii=False)
            os.replace(temporary, self.path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def _load(self) -> None:
        if not self.path.is_file():
            return
        with self.path.open("r", encoding="utf-8") as stream:
            payload = json.load(stream)
        if payload.get("format_version") != 1:
            raise ValueError("Format du modèle FIRA non pris en charge.")
        self.token_count = int(payload.get("token_count", 0))
        self.training_documents = int(payload.get("training_documents", 0))
        for key, values in payload.get("transitions", {}).items():
            self.transitions[key].update({str(token): int(count) for token, count in values.items()})


language_model = NGramLanguageModel()
