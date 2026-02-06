import json
import os
import joblib
import numpy as np

from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report

from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier


def main():
    iris = load_iris()
    X = iris.data
    y = iris.target

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    pipe = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", LogisticRegression(max_iter=2000))
    ])

    param_grid = [
        {
            "clf": [LogisticRegression(max_iter=2000)],
            "clf__C": [0.1, 1.0, 10.0],
            "clf__solver": ["lbfgs"],
        },
        {
            "clf": [SVC(probability=True)],
            "clf__C": [0.1, 1.0, 10.0],
            "clf__kernel": ["rbf", "linear"],
            "clf__gamma": ["scale", "auto"],
        },
        {
            "clf": [RandomForestClassifier(random_state=42)],
            "clf__n_estimators": [50, 150, 300],
            "clf__max_depth": [None, 3, 5],
            "clf__min_samples_split": [2, 5],
        }
    ]

    search = GridSearchCV(
        estimator=pipe,
        param_grid=param_grid,
        scoring="accuracy",
        cv=5,
        n_jobs=-1,
        verbose=1,
    )

    search.fit(X_train, y_train)

    best_model = search.best_estimator_
    y_pred = best_model.predict(X_test)

    acc = accuracy_score(y_test, y_pred)
    report = classification_report(
        y_test, y_pred, target_names=iris.target_names, output_dict=True
    )

    os.makedirs("artifacts", exist_ok=True)

    joblib.dump(
        {
            "model": best_model,
            "target_names": iris.target_names.tolist(),
            "feature_names": iris.feature_names,
        },
        "artifacts/model.pkl",
    )

    # Tornar best_params serializável (pois pode conter o objeto do estimador em "clf")
    best_params = dict(search.best_params_)
    if "clf" in best_params:
        best_params["clf"] = best_params["clf"].__class__.__name__

    with open("artifacts/metrics.json", "w", encoding="utf-8") as f:
        json.dump(
            {
                "best_params": best_params,
                "best_cv_score": float(search.best_score_),
                "test_accuracy": float(acc),
                "classification_report": report,
                "best_model_class": best_model.named_steps["clf"].__class__.__name__,
            },
            f,
            indent=2,
        )

    print("Saved artifacts/model.pkl and artifacts/metrics.json")
    print("Best CV score:", search.best_score_)
    print("Test accuracy:", acc)


if __name__ == "__main__":
    main()
