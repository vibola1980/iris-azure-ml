"""
Iris Model Training Script
Trains a Random Forest classifier on the Iris dataset
Outputs model to ../models/model.pkl
"""

import os
import joblib
from datetime import datetime
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score


def train_model():
    """Train and save the Iris classification model"""
    print("=" * 50)
    print("Iris Model Training")
    print("=" * 50)
    print(f"Started at: {datetime.now().isoformat()}")
    print()

    # Load dataset
    print("Loading Iris dataset...")
    iris = load_iris()
    X, y = iris.data, iris.target

    print(f"  Samples: {len(X)}")
    print(f"  Features: {X.shape[1]}")
    print(f"  Classes: {list(iris.target_names)}")
    print()

    # Split data
    print("Splitting data (80% train, 20% test)...")
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    print(f"  Training samples: {len(X_train)}")
    print(f"  Test samples: {len(X_test)}")
    print()

    # Train model
    print("Training Random Forest classifier...")
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=5,
        random_state=42,
        n_jobs=-1
    )
    model.fit(X_train, y_train)
    print("  Training complete")
    print()

    # Cross-validation
    print("Cross-validation (5-fold)...")
    cv_scores = cross_val_score(model, X_train, y_train, cv=5)
    print(f"  Mean CV accuracy: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")
    print()

    # Evaluate on test set
    print("Evaluation on test set:")
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"  Test accuracy: {accuracy:.4f}")
    print()

    print("Classification Report:")
    print(classification_report(y_test, y_pred, target_names=iris.target_names))

    # Feature importance
    print("Feature Importance:")
    for name, importance in zip(
        ["sepal_length", "sepal_width", "petal_length", "petal_width"],
        model.feature_importances_
    ):
        print(f"  {name}: {importance:.4f}")
    print()

    # Save model
    output_dir = os.path.join(os.path.dirname(__file__), "..", "models")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "model.pkl")

    print(f"Saving model to {output_path}...")
    joblib.dump(model, output_path)
    print("  Model saved successfully")
    print()

    print("=" * 50)
    print(f"Training completed at: {datetime.now().isoformat()}")
    print("=" * 50)

    return model, accuracy


if __name__ == "__main__":
    train_model()
