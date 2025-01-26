<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Habit Details</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
            background-color: rgba(218, 226, 227, 0.719);
        }
        .date-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 5px;
        }
        .date-cell {
            border: 1px solid #ccc;
            padding: 10px;
            text-align: center;
            position: relative;
        }
        .date-cell.completed {
            background-color: rgba(0, 255, 0, 0.2);
        }
        .streak-stats {
            display: flex;
            justify-content: space-around;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <h1 id="habitName">Habit Details</h1>

    <div class="streak-stats">
        <div id="currentStreakBox">
            <h3>Current Streak</h3>
            <p id="currentStreakCount">0 days</p>
        </div>
        <div id="longestStreakBox">
            <h3>Longest Streak</h3>
            <p id="longestStreakCount">0 days</p>
        </div>
    </div>

    <div class="date-grid" id="dateGrid"></div>

    <div>
        <button id="completeBtn">Complete Today</button>
        <button onclick="window.location.href='index.html'">Back to Habits</button>
    </div>

    <script>
        class HabitTracker {
            constructor(habitName, habitColor) {
                this.habitName = habitName;
                this.habitColor = habitColor;
                this.loadData();
                this.renderGrid();
            }

            loadData() {
                const savedData = JSON.parse(localStorage.getItem(`habit_tracking_${this.habitName}`) || '{}');
                
                this.completedDays = savedData.completedDays || [];
                this.currentStreak = savedData.currentStreak || 0;
                this.longestStreak = savedData.longestStreak || 0;
            }

            saveData() {
                const data = {
                    completedDays: this.completedDays,
                    currentStreak: this.currentStreak,
                    longestStreak: this.longestStreak
                };
                localStorage.setItem(`habit_tracking_${this.habitName}`, JSON.stringify(data));
            }

            renderGrid() {
                const grid = document.getElementById('dateGrid');
                grid.innerHTML = '';

                // Create headers
                const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                days.forEach(day => {
                    const headerCell = document.createElement('div');
                    headerCell.textContent = day;
                    headerCell.style.fontWeight = 'bold';
                    grid.appendChild(headerCell);
                });

                // Generate dates for current month
                const today = new Date();
                const month = today.getMonth();
                const year = today.getFullYear();
                const daysInMonth = new Date(year, month + 1, 0).getDate();
                const firstDay = new Date(year, month, 1).getDay();

                // Add empty cells for days before the first day
                for (let i = 0; i < firstDay; i++) {
                    grid.appendChild(document.createElement('div'));
                }

                // Add date cells
                for (let day = 1; day <= daysInMonth; day++) {
                    const dateCell = document.createElement('div');
                    dateCell.classList.add('date-cell');
                    dateCell.textContent = day;

                    // Format date for comparison
                    const formattedDate = this.formatDate(new Date(year, month, day));
                    
                    // Mark completed days
                    if (this.completedDays.includes(formattedDate)) {
                        dateCell.classList.add('completed');
                        dateCell.style.backgroundColor = `${this.habitColor}80`;
                    }

                    grid.appendChild(dateCell);
                }
            }

            formatDate(date) {
                return date.toISOString().split('T')[0];
            }

            completeToday() {
                const today = this.formatDate(new Date());
                const yesterday = this.formatDate(new Date(Date.now() - 86400000));

                if (!this.completedDays.includes(today)) {
                    // Streak logic
                    if (this.completedDays.includes(yesterday)) {
                        this.currentStreak++;
                    } else {
                        this.currentStreak = 1;
                    }

                    this.longestStreak = Math.max(this.longestStreak, this.currentStreak);

                    this.completedDays.push(today);
                    this.completedDays.sort();
                    this.saveData();
                    return true;
                }
                
                return false;
            }
        }

        let habitTracker;

        function initHabitDetails() {
            const urlParams = new URLSearchParams(window.location.search);
            const habitName = urlParams.get('habit');
            const habitColor = urlParams.get('color');
            
            document.getElementById('habitName').textContent = habitName;
            
            habitTracker = new HabitTracker(habitName, habitColor);

            document.getElementById('completeBtn').addEventListener('click', completeHabit);
            updateStreakDisplay();
        }

        function completeHabit() {
            if (habitTracker.completeToday()) {
                habitTracker.renderGrid();
                updateStreakDisplay();
                alert('Habit completed for today!');
            } else {
                alert('You have already completed this habit today!');
            }
        }

        function updateStreakDisplay() {
            document.getElementById('currentStreakCount').textContent = `${habitTracker.currentStreak} days`;
            document.getElementById('longestStreakCount').textContent = `${habitTracker.longestStreak} days`;
        }

        document.addEventListener('DOMContentLoaded', initHabitDetails);
    </script>
</body>
</html>
