"""
Tabela comparativa v1 vs v2 para demo.
Usage: python compare_results.py .demo-results-v1.json .demo-results-v2.json
"""
import json
import sys
import os

# Force UTF-8 output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    os.environ.setdefault("PYTHONIOENCODING", "utf-8")

CLASSES = ["setosa", "versicolor", "virginica"]
INPUTS = [
    "[5.1, 3.5, 1.4, 0.2]",
    "[6.0, 2.7, 4.5, 1.5]",
    "[6.7, 3.0, 5.2, 2.3]",
]
LABELS = ["Setosa tipica", "Versicolor (ambigua)", "Virginica (dificil)"]


def load_results(path):
    with open(path) as f:
        return json.load(f)


def pct(val):
    return f"{val * 100:5.1f}%"


def bar(val, width=20):
    filled = int(val * width)
    return "#" * filled + "." * (width - filled)


def print_comparison(v1_results, v2_results):
    W = 80
    sep = "=" * W
    thin = "-" * W

    print()
    print(sep)
    print("  TABELA COMPARATIVA: v1 (sepal_only) vs v2 (all_features)")
    print(sep)

    for i in range(3):
        v1 = v1_results[i]
        v2 = v2_results[i]
        v1_probs = v1["probabilities"]
        v2_probs = v2["probabilities"]

        print()
        print(f"  Predicao {i+1}: {LABELS[i]}")
        print(f"  Input: {INPUTS[i]}")
        print(thin)
        print(f"  {'Classe':<14}{'v1 (sepal_only)':^30}  {'v2 (all_features)':^30}")
        print(f"  {'':-<14}{'':-^30}  {'':-^30}")

        for j, cls in enumerate(CLASSES):
            p1 = v1_probs[j]
            p2 = v2_probs[j]

            # Highlight the predicted class
            marker_v1 = " <" if j == v1["predicted_class_id"] else "  "
            marker_v2 = " <" if j == v2["predicted_class_id"] else "  "

            line_v1 = f"{bar(p1)} {pct(p1)}{marker_v1}"
            line_v2 = f"{bar(p2)} {pct(p2)}{marker_v2}"
            print(f"  {cls:<14}{line_v1}  {line_v2}")

        # Show verdict
        v1_max = max(v1_probs)
        v2_max = max(v2_probs)
        v1_conf = "BAIXA" if v1_max < 0.7 else "MEDIA" if v1_max < 0.9 else "ALTA"
        v2_conf = "BAIXA" if v2_max < 0.7 else "MEDIA" if v2_max < 0.9 else "ALTA"

        print(f"  {'':-<14}{'':-^30}  {'':-^30}")
        print(
            f"  {'Confianca':<14}{'':>10}{v1_conf:^10}{'':>10}"
            f"  {'':>10}{v2_conf:^10}{'':>10}"
        )
        print(
            f"  {'Predicao':<14}{'':>5}{v1['predicted_class_name']:^20}{'':>5}"
            f"  {'':>5}{v2['predicted_class_name']:^20}{'':>5}"
        )

    print()
    print(sep)
    print("  CONCLUSAO:")
    print("    v1 (sepal_only)   -> Modelo com 2 features, probabilidades DISPERSAS")
    print("    v2 (all_features) -> Modelo com 4 features, probabilidades CONCENTRADAS")
    print()
    print("    Adicionar petal_length e petal_width melhorou drasticamente")
    print("    a confianca do modelo na classificacao.")
    print(sep)
    print()


if __name__ == "__main__":
    v1_file = sys.argv[1]
    v2_file = sys.argv[2]
    v1_results = load_results(v1_file)
    v2_results = load_results(v2_file)
    print_comparison(v1_results, v2_results)
