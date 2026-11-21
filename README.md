<div align="center">
  <img src="./assets/banner.svg" width="100%" alt="FoodRecipe v2.0 Banner" />
</div>

<p align="center">
  <img src="https://img.shields.io/badge/Swift_6.0-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 6" />
  <img src="https://img.shields.io/badge/iOS_17%2B-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 17+" />
  <img src="https://img.shields.io/badge/Architecture-Protocol--Oriented_MVVM-F5852E?style=for-the-badge" alt="MVVM" />
  <img src="https://img.shields.io/badge/Swift_Charts-Macro_Telemetry-29C78A?style=for-the-badge" alt="Swift Charts" />
</p>

**FoodRecipe v2.0** is a native iOS culinary discovery, smart pantry ingredient matcher, hands-free cooking timer, and macro meal planner built with **Swift 6**, **SwiftUI**, **Combine**, **Swift Charts**, and **Protocol-Oriented MVVM**.

---

## Key Engineering Highlights

- **Smart Pantry Ingredient Matcher (`PantryMatcherViewModel`)**: Scores and ranks recipes in real time by **Pantry Match %** based on the ingredients currently available in the user's kitchen, isolating missing items for 1-tap export to the shopping cart.
- **Hybrid Live + Offline Recipe Engine (`LiveRecipeRepository`)**: Fetches live dishes and high-resolution meal photography asynchronously from [`TheMealDB` Open API](https://www.themealdb.com/api.php) while bundling an offline-first curated chef catalog (Anatolian, Mediterranean, High-Protein, Italian, and Asian bowls).
- **Actor-Isolated Image Caching (`actor RemoteImageCache`)**: Two-tier (`NSCache` memory + disk directory) image pipeline with **in-flight task coalescing** to prevent duplicate network requests while scrolling.
- **Dynamic Portion & Macro Scaling (`Recipe.scaledIngredients(forServings:)`)**: Pure functional scaling engine that recalculates gram/unit measurements and calorie/protein/carb/fat totals dynamically from `1` to `12` servings.
- **Hands-Free Step-by-Step Cooking Mode (`CookingSessionView`)**: High-contrast full-screen kitchen assistant with per-step countdown timers, progress tracking, and chef tips.
- **Weekly Macro Analytics & Aisle-Grouped Shopping List (`MealPlannerView`)**: Native **Swift Charts** visualization comparing scheduled daily calories and protein against user targets, paired with an automated grocery list organized by supermarket aisle.

---

## System Architecture

```mermaid
flowchart LR
    subgraph UI["SwiftUI Feature Layer (Features/ & UI/)"]
        EX["ExploreView & RecipeDetailView"]
        PM["PantryMatcherView (Match % Engine)"]
        CM["CookingSessionView (Step Timers)"]
        MP["MealPlannerView (Swift Charts)"]
    end

    subgraph VM["@MainActor ViewModels"]
        EVM["ExploreViewModel (Combine Debounce)"]
        PVM["PantryMatcherViewModel"]
        CVM["CookingSessionViewModel"]
        MVM["MealPlannerViewModel"]
    end

    subgraph Core["Core Domain, Networking & Persistence"]
        REP["RecipeRepositoryProtocol / LiveRecipeRepository"]
        IMG["actor RemoteImageCache (NSCache + Disk)"]
        STR["KitchenStore (Pantry, Meal Plan & Cart)"]
    end

    EX --> EVM
    PM --> PVM
    CM --> CVM
    MP --> MVM
    EVM --> REP
    EX --> IMG
    EVM --> STR
    PVM --> STR
    MVM --> STR
```

---

## Directory Structure

```text
FoodRecipe/
├── App/
│   ├── FoodRecipeApp.swift            # App entry point & DI root
│   └── MainTabView.swift              # 4-tab dark-mode navigation shell
├── Core/
│   ├── DI/
│   │   └── AppContainer.swift         # Protocol-oriented dependency container
│   ├── Models/
│   │   └── RecipeModels.swift         # Recipe, MacroBreakdown, PantryMatchResult, CookingStep
│   ├── Networking/
│   │   ├── RecipeRepository.swift     # TheMealDB async client + offline chef catalog
│   │   └── RemoteImageCache.swift     # Actor-isolated memory + disk image cache
│   └── Persistence/
│       └── KitchenStore.swift         # Favorites, Pantry inventory, Weekly Meal Plan & Cart
├── Features/
│   ├── CookingMode/                   # Hands-free step timer assistant
│   ├── Explore/                       # Recipe search, cuisine filters & dynamic portion scaler
│   ├── Favorites/                     # Saved personal cookbook
│   ├── MealPlanner/                   # Swift Charts weekly calorie/macro telemetry & aisle cart
│   └── PantryMatcher/                 # "What's in My Kitchen?" % match ranking engine
├── UI/
│   ├── Components/
│   │   ├── CachedMealImageView.swift  # Async cached dish photography view
│   │   └── MacroRingBadge.swift       # Circular protein/carb/fat telemetry ring
│   └── Theme/
│       └── CulinaryTheme.swift        # Saffron & Emerald dark-mode design tokens
└── FoodRecipeTests/
    └── FoodRecipeTests.swift          # XCTest suite for portion scaling, pantry matching & macros
```

---

## Verification & Typecheck

```bash
swiftc -typecheck \
  -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -target arm64-apple-ios17.0-simulator \
  $(find FoodRecipe -name '*.swift') FoodRecipeTests/FoodRecipeTests.swift
```
