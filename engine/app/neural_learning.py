"""Tiny trainable neural bigram language model implemented from scratch with NumPy.

No pretrained weights or external inference service. This is a learning experiment,
not a conversational assistant. Vocabulary and parameters are learned from supplied text.
"""
from __future__ import annotations

import json
import os
import re
from pathlib import Path

import numpy as np

_TOKEN_RE = re.compile(r"\w+(?:['’]\w+)?|[^\w\s]", re.UNICODE)
_UNK = "<UNK>"
_END = "<END>"


class TinyNeuralLanguageModel:
    def __init__(self, path: str | Path | None = None, embedding_size: int = 24) -> None:
        default_path = Path(__file__).resolve().parent.parent / "data" / "fira_tiny_neural.npz"
        self.path = Path(path or os.getenv("FIRA_NEURAL_MODEL_PATH", str(default_path)))
        self.embedding_size = embedding_size
        self.vocabulary: list[str] = []
        self.embeddings = np.zeros((0, embedding_size), dtype=np.float32)
        self.output_weights = np.zeros((embedding_size, 0), dtype=np.float32)
        self.output_bias = np.zeros((1, 0), dtype=np.float32)
        self.training_steps = 0
        self.training_tokens = 0
        self._load()

    @staticmethod
    def tokenize(text: str) -> list[str]:
        return _TOKEN_RE.findall(text)

    def status(self) -> dict[str, object]:
        return {
            "trained": bool(self.vocabulary),
            "model_type": "tiny-neural-bigram",
            "pretrained_weights": False,
            "external_ai_api": False,
            "vocabulary_size": len(self.vocabulary),
            "embedding_size": self.embedding_size,
            "training_steps": self.training_steps,
            "training_tokens": self.training_tokens,
        }

    def train(self, text: str, epochs: int = 3, learning_rate: float = 0.08) -> dict[str, int | float]:
        tokens = self.tokenize(text)
        if len(tokens) < 20:
            raise ValueError("Fournissez au moins 20 unités lexicales pour entraîner le réseau.")
        if not 1 <= epochs <= 10:
            raise ValueError("Le nombre d'époques doit être compris entre 1 et 10.")
        from collections import Counter
        counts = Counter(tokens)
        vocab = [_UNK, _END] + [word for word, _ in counts.most_common(510) if word not in {_UNK, _END}]
        token_to_id = {token: index for index, token in enumerate(vocab)}
        ids = [token_to_id.get(token, 0) for token in tokens] + [token_to_id[_END]]
        x = np.asarray(ids[:-1], dtype=np.int64)
        y = np.asarray(ids[1:], dtype=np.int64)
        size = len(vocab)
        rng = np.random.default_rng(17 + self.training_steps)
        if self.vocabulary:
            old = {token: i for i, token in enumerate(self.vocabulary)}
            new_embeddings = rng.normal(0, 0.04, (size, self.embedding_size)).astype(np.float32)
            for i, token in enumerate(vocab):
                if token in old:
                    new_embeddings[i] = self.embeddings[old[token]]
            new_weights = rng.normal(0, 0.04, (self.embedding_size, size)).astype(np.float32)
            for i, token in enumerate(vocab):
                if token in old:
                    new_weights[:, i] = self.output_weights[:, old[token]]
            self.embeddings, self.output_weights = new_embeddings, new_weights
            self.output_bias = np.zeros((1, size), dtype=np.float32)
        else:
            self.embeddings = rng.normal(0, 0.04, (size, self.embedding_size)).astype(np.float32)
            self.output_weights = rng.normal(0, 0.04, (self.embedding_size, size)).astype(np.float32)
            self.output_bias = np.zeros((1, size), dtype=np.float32)
        self.vocabulary = vocab
        losses: list[float] = []
        order = np.arange(len(x))
        for _ in range(epochs):
            rng.shuffle(order)
            epoch_loss = 0.0
            for start in range(0, len(order), 64):
                batch = order[start:start + 64]
                xb, yb = x[batch], y[batch]
                hidden = self.embeddings[xb]
                logits = hidden @ self.output_weights + self.output_bias
                logits -= logits.max(axis=1, keepdims=True)
                probs = np.exp(logits)
                probs /= probs.sum(axis=1, keepdims=True)
                epoch_loss += float(-np.log(probs[np.arange(len(yb)), yb] + 1e-9).sum())
                grad = probs
                grad[np.arange(len(yb)), yb] -= 1.0
                grad /= len(yb)
                grad_w = hidden.T @ grad
                grad_b = grad.sum(axis=0, keepdims=True)
                grad_h = grad @ self.output_weights.T
                np.add.at(self.embeddings, xb, -learning_rate * grad_h)
                self.output_weights -= learning_rate * grad_w
                self.output_bias -= learning_rate * grad_b
            losses.append(epoch_loss / len(order))
        self.training_steps += epochs
        self.training_tokens += len(tokens)
        self.save()
        return {"new_tokens": len(tokens), "vocabulary_size": size, "epochs": epochs,
                "training_steps": self.training_steps, "final_loss": round(losses[-1], 4)}

    def generate(self, seed_text: str = "", max_tokens: int = 40, seed: int | None = None) -> str:
        if not self.vocabulary:
            raise RuntimeError("Le réseau neuronal FIRA n'a pas encore été entraîné.")
        rng = np.random.default_rng(seed)
        ids = {token: i for i, token in enumerate(self.vocabulary)}
        words = self.tokenize(seed_text)
        previous = ids.get(words[-1], 0) if words else 0
        output = list(words)
        for _ in range(max_tokens):
            hidden = self.embeddings[previous:previous + 1]
            logits = (hidden @ self.output_weights + self.output_bias)[0]
            logits -= logits.max()
            probs = np.exp(logits)
            probs /= probs.sum()
            next_id = int(rng.choice(len(self.vocabulary), p=probs))
            token = self.vocabulary[next_id]
            if token == _END:
                break
            if token != _UNK:
                output.append(token)
            previous = next_id
        return self._detokenize(output)

    @staticmethod
    def _detokenize(tokens: list[str]) -> str:
        result = ""
        no_space_before = {".", ",", ";", ":", "!", "?", ")", "]"}
        for token in tokens:
            if not result or token in no_space_before or result.endswith(("(", "[")):
                result += token
            else:
                result += " " + token
        return result.strip()

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        np.savez_compressed(
            self.path,
            vocabulary=np.asarray(self.vocabulary, dtype=np.str_),
            embeddings=self.embeddings,
            output_weights=self.output_weights,
            output_bias=self.output_bias,
            training_steps=np.asarray([self.training_steps], dtype=np.int64),
            training_tokens=np.asarray([self.training_tokens], dtype=np.int64),
        )

    def _load(self) -> None:
        if not self.path.is_file():
            return
        with np.load(self.path, allow_pickle=False) as data:
            self.vocabulary = data["vocabulary"].tolist()
            self.embeddings = data["embeddings"].astype(np.float32)
            self.output_weights = data["output_weights"].astype(np.float32)
            self.output_bias = data["output_bias"].astype(np.float32)
            self.training_steps = int(data["training_steps"][0])
            self.training_tokens = int(data["training_tokens"][0])
            self.embedding_size = int(self.embeddings.shape[1])


neural_model = TinyNeuralLanguageModel()
