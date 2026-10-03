import 'models.dart';

const kCatalogExercises = <CatalogExercise>[
  CatalogExercise(
    id: 'push_up',
    name: 'Push-Up',
    muscles: ['chest', 'triceps', 'shoulders'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Start in a high plank with hands under your shoulders and body in a straight line.\n'
        '2. Brace your core and squeeze your glutes to keep your hips level.\n'
        '3. Lower your chest toward the floor by bending your elbows at roughly 45 degrees.\n'
        '4. Press through your palms to push back up to the start position.\n'
        '5. Repeat for the target reps without letting your hips sag.',
    tips: 'Keep your neck neutral by looking at the floor just ahead of your hands.',
  ),
  CatalogExercise(
    id: 'knee_push_up',
    name: 'Knee Push-Up',
    muscles: ['chest', 'triceps', 'shoulders'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Start in a high plank, then lower your knees to the floor.\n'
        '2. Keep your body in a straight line from knees to head.\n'
        '3. Lower your chest toward the floor, bending elbows at about 45 degrees.\n'
        '4. Press back up through your palms.\n'
        '5. Repeat, keeping your core braced the whole time.',
    tips: 'Slide your knees back so your hips stay ahead of your knees.',
  ),
  CatalogExercise(
    id: 'incline_push_up',
    name: 'Incline Push-Up',
    muscles: ['chest', 'triceps', 'shoulders'],
    equipment: ['chair'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Place your hands on a sturdy chair or bench, slightly wider than shoulder width.\n'
        '2. Step your feet back into a plank position with a straight line from head to heels.\n'
        '3. Lower your chest toward the chair by bending your elbows.\n'
        '4. Push back up to the start position.\n'
        '5. Keep your core tight so your hips do not sag.',
    tips: 'The higher the surface, the easier the rep.',
  ),
  CatalogExercise(
    id: 'diamond_push_up',
    name: 'Diamond Push-Up',
    muscles: ['chest', 'triceps'],
    equipment: ['bodyweight'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Start in a high plank and bring your hands together under your chest.\n'
        '2. Form a diamond shape with your thumbs and index fingers.\n'
        '3. Lower your chest toward your hands, keeping elbows close to your body.\n'
        '4. Press back up until your arms are straight.\n'
        '5. Keep your hips level and core braced throughout.',
    tips: 'Stop short of full lockout if your elbows feel strained.',
  ),
  CatalogExercise(
    id: 'archer_push_up',
    name: 'Archer Push-Up',
    muscles: ['chest', 'triceps', 'shoulders'],
    equipment: ['bodyweight'],
    difficulty: 'advanced',
    type: 'strength',
    instructions:
        '1. Start in a wide push-up position with hands well outside shoulder width.\n'
        '2. Shift your weight toward one hand as you lower your chest to that side.\n'
        '3. Keep the opposite arm nearly straight as it guides the movement.\n'
        '4. Press back up to the start position.\n'
        '5. Alternate sides each rep, keeping your body rigid.',
    tips: 'Think of the straight arm as a sliding support, not a lifter.',
  ),
  CatalogExercise(
    id: 'bench_press',
    name: 'Dumbbell Bench Press',
    muscles: ['chest', 'triceps', 'shoulders'],
    equipment: ['dumbbell', 'bench'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Lie on a bench with a dumbbell in each hand at chest level, palms facing forward.\n'
        '2. Plant your feet firmly on the floor and keep your back naturally arched.\n'
        '3. Press the weights straight up until your arms are extended.\n'
        '4. Lower them slowly back to chest level with control.\n'
        '5. Pause briefly, then repeat.',
    tips: 'Keep your wrists stacked over your elbows, not tipped backward.',
  ),
  CatalogExercise(
    id: 'dumbbell_fly',
    name: 'Dumbbell Chest Fly',
    muscles: ['chest', 'shoulders'],
    equipment: ['dumbbell', 'bench'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Lie on a bench with dumbbells held above your chest, palms facing each other.\n'
        '2. Keep a soft bend in your elbows and lock that angle in place.\n'
        '3. Lower the weights out to the sides in a wide arc until you feel a chest stretch.\n'
        '4. Squeeze your chest to bring the weights back together above you.\n'
        '5. Repeat slowly, never letting your elbows drop below your torso.',
    tips: 'Hug a wide invisible barrel; do not let your elbows bend and unbend.',
  ),
  CatalogExercise(
    id: 'overhead_press',
    name: 'Overhead Press',
    muscles: ['shoulders', 'triceps', 'core'],
    equipment: ['dumbbell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Stand tall with feet hip-width apart, dumbbells at shoulder height.\n'
        '2. Brace your core and keep your ribs down.\n'
        '3. Press the weights overhead until your arms are straight.\n'
        '4. Lower them back to shoulder height with control.\n'
        '5. Avoid leaning back as the weights go up.',
    tips: 'Squeeze your glutes to protect your lower back.',
  ),
  CatalogExercise(
    id: 'lateral_raise',
    name: 'Lateral Raise',
    muscles: ['shoulders'],
    equipment: ['dumbbell'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Stand with a dumbbell in each hand at your sides, palms facing in.\n'
        '2. Keep a slight bend in your elbows.\n'
        '3. Raise the weights out to the sides until your arms are parallel to the floor.\n'
        '4. Pause briefly at the top.\n'
        '5. Lower slowly back to your sides.',
    tips: 'Lead with your elbows, as if pouring water from two pitchers.',
  ),
  CatalogExercise(
    id: 'front_raise',
    name: 'Front Raise',
    muscles: ['shoulders', 'chest'],
    equipment: ['dumbbell'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Stand tall with a dumbbell in each hand in front of your thighs.\n'
        '2. Keeping your arms straight with a soft elbow, raise one arm forward to shoulder height.\n'
        '3. Lower it slowly, then raise the other arm.\n'
        '4. Alternate arms for the target reps.\n'
        '5. Keep your torso still; do not swing or lean back.',
    tips: 'Stop the lift at shoulder height to protect your shoulders.',
  ),
  CatalogExercise(
    id: 'bent_over_row',
    name: 'Bent-Over Row',
    muscles: ['back', 'biceps'],
    equipment: ['dumbbell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Hold a dumbbell in each hand and hinge at your hips until your torso is near parallel to the floor.\n'
        '2. Let the weights hang with your back flat and core braced.\n'
        '3. Pull both dumbbells toward your lower ribs, squeezing your shoulder blades together.\n'
        '4. Lower the weights slowly back to the hang.\n'
        '5. Keep your head in line with your spine throughout.',
    tips: 'Drive your elbows toward the ceiling, not out to the sides.',
  ),
  CatalogExercise(
    id: 'single_arm_row',
    name: 'Single-Arm Dumbbell Row',
    muscles: ['back', 'biceps'],
    equipment: ['dumbbell', 'bench'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Place one knee and the same-side hand on a bench; keep your back flat.\n'
        '2. Hold a dumbbell in the free hand, arm hanging straight down.\n'
        '3. Pull the dumbbell up toward your hip, squeezing your shoulder blade.\n'
        '4. Lower it slowly to full arm extension.\n'
        '5. Complete all reps, then switch sides.',
    tips: 'Row toward your hip pocket to hit the lats, not your chest.',
  ),
  CatalogExercise(
    id: 'band_lat_pulldown',
    name: 'Resistance Band Lat Pulldown',
    muscles: ['back', 'biceps'],
    equipment: ['resistance band'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Anchor a resistance band overhead on a door or sturdy frame.\n'
        '2. Hold the band with both hands, arms extended overhead and slightly wider than shoulders.\n'
        '3. Pull the band down toward your upper chest, driving elbows down and back.\n'
        '4. Squeeze your shoulder blades together at the bottom.\n'
        '5. Return slowly to the start position.',
    tips: 'Keep your chest lifted and ribs down as you pull.',
  ),
  CatalogExercise(
    id: 'pull_up',
    name: 'Pull-Up',
    muscles: ['back', 'biceps', 'forearms'],
    equipment: ['pull-up bar'],
    difficulty: 'advanced',
    type: 'strength',
    instructions:
        '1. Hang from a pull-up bar with an overhand grip, hands just outside shoulder width.\n'
        '2. Start from a dead hang with shoulders pulled slightly down and back.\n'
        '3. Pull your chest toward the bar until your chin clears it.\n'
        '4. Pause briefly at the top.\n'
        '5. Lower yourself slowly to a full hang.',
    tips: 'Think of pulling your elbows into your ribs.',
  ),
  CatalogExercise(
    id: 'face_pull',
    name: 'Face Pull',
    muscles: ['back', 'shoulders'],
    equipment: ['resistance band'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Anchor a resistance band at chest height.\n'
        '2. Grip the band with both hands, thumbs toward you, and step back for tension.\n'
        '3. Pull the band toward your forehead, flaring your elbows out to the sides.\n'
        '4. Externally rotate so your knuckles face the ceiling at the end.\n'
        '5. Return slowly to the start position.',
    tips: 'Pinch your shoulder blades together like squeezing a pencil.',
  ),
  CatalogExercise(
    id: 'superman',
    name: 'Superman',
    muscles: ['back', 'glutes'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Lie face down on a mat with arms extended overhead and legs straight.\n'
        '2. Brace your core and keep your neck neutral.\n'
        '3. Lift your arms, chest, and legs off the floor at the same time.\n'
        '4. Hold for two to three seconds at the top.\n'
        '5. Lower back down with control and repeat.',
    tips: 'Look at the floor to keep your neck long and relaxed.',
  ),
  CatalogExercise(
    id: 'bicep_curl',
    name: 'Bicep Curl',
    muscles: ['biceps', 'forearms'],
    equipment: ['dumbbell'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Stand with a dumbbell in each hand at your sides, palms facing forward.\n'
        '2. Pin your elbows to your sides.\n'
        '3. Curl the weights toward your shoulders by bending only at the elbow.\n'
        '4. Squeeze at the top for a brief pause.\n'
        '5. Lower slowly back to the start.',
    tips: 'Keep your upper arms still; no swinging from the shoulders.',
  ),
  CatalogExercise(
    id: 'hammer_curl',
    name: 'Hammer Curl',
    muscles: ['biceps', 'forearms'],
    equipment: ['dumbbell'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Stand with a dumbbell in each hand, palms facing your thighs.\n'
        '2. Keep your elbows pinned to your sides.\n'
        '3. Curl the weights up toward your shoulders without rotating your wrists.\n'
        '4. Pause at the top.\n'
        '5. Lower slowly to the start position.',
    tips: 'Move like you are hammering a nail in front of your shoulder.',
  ),
  CatalogExercise(
    id: 'tricep_dip',
    name: 'Tricep Dip',
    muscles: ['triceps', 'shoulders', 'chest'],
    equipment: ['chair'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Sit on the edge of a sturdy chair with hands gripping the edge beside your hips.\n'
        '2. Walk your feet forward and lift your hips off the chair.\n'
        '3. Bend your elbows to lower your body until your upper arms are near parallel to the floor.\n'
        '4. Press through your palms to straighten your arms.\n'
        '5. Keep your back close to the chair throughout.',
    tips: 'Bend your knees to make it easier, straighten them to make it harder.',
  ),
  CatalogExercise(
    id: 'overhead_tricep_extension',
    name: 'Overhead Tricep Extension',
    muscles: ['triceps'],
    equipment: ['dumbbell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Stand or sit tall holding one dumbbell with both hands overhead.\n'
        '2. Keep your elbows pointing forward and close to your head.\n'
        '3. Lower the dumbbell behind your head by bending only at the elbows.\n'
        '4. Extend your arms back overhead until straight.\n'
        '5. Keep your upper arms still and core braced.',
    tips: 'Do not let your elbows flare wide; keep them tracking forward.',
  ),
  CatalogExercise(
    id: 'wrist_curl',
    name: 'Dumbbell Wrist Curl',
    muscles: ['forearms'],
    equipment: ['dumbbell'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Sit and rest your forearms on your thighs, wrists just past your knees.\n'
        '2. Hold a light dumbbell in each hand, palms facing up.\n'
        '3. Curl your wrists upward, lifting the weights as high as comfortable.\n'
        '4. Pause briefly at the top.\n'
        '5. Lower slowly to the start position.',
    tips: 'Use very light weight; forearms respond best to high reps.',
  ),
  CatalogExercise(
    id: 'bodyweight_squat',
    name: 'Bodyweight Squat',
    muscles: ['quadriceps', 'glutes', 'hamstrings'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Stand with feet shoulder-width apart, toes slightly out.\n'
        '2. Push your hips back and bend your knees to lower down.\n'
        '3. Keep your chest up and knees tracking over your toes.\n'
        '4. Lower until your thighs are at least parallel to the floor.\n'
        '5. Drive through your heels to stand back up.',
    tips: 'Sit back like lowering into a chair behind you.',
  ),
  CatalogExercise(
    id: 'goblet_squat',
    name: 'Goblet Squat',
    muscles: ['quadriceps', 'glutes', 'core'],
    equipment: ['dumbbell'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Hold a dumbbell vertically at chest height with both hands.\n'
        '2. Stand with feet slightly wider than shoulder width, toes out.\n'
        '3. Push your hips back and lower into a squat, keeping the weight close.\n'
        '4. Keep your chest up and elbows inside your knees at the bottom.\n'
        '5. Drive through your heels to stand.',
    tips: 'Use the weight as a counterbalance to stay upright.',
  ),
  CatalogExercise(
    id: 'split_squat',
    name: 'Split Squat',
    muscles: ['quadriceps', 'glutes'],
    equipment: ['bodyweight'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Take a long staggered stance with one foot forward and one back.\n'
        '2. Keep your torso upright and hands on your hips or at your sides.\n'
        '3. Lower straight down until your front thigh is parallel to the floor.\n'
        '4. Press through your front heel to rise back up.\n'
        '5. Complete all reps, then switch legs.',
    tips: 'Keep most of your weight on the front leg; the back leg steadies you.',
  ),
  CatalogExercise(
    id: 'forward_lunge',
    name: 'Forward Lunge',
    muscles: ['quadriceps', 'glutes', 'hamstrings'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Stand tall with feet together and hands on your hips.\n'
        '2. Step forward with one foot into a long stride.\n'
        '3. Lower your hips until both knees are bent at about 90 degrees.\n'
        '4. Push through your front heel to return to standing.\n'
        '5. Alternate legs each rep.',
    tips: 'Keep your front knee behind your toes and torso upright.',
  ),
  CatalogExercise(
    id: 'walking_lunge',
    name: 'Walking Lunge',
    muscles: ['quadriceps', 'glutes', 'hamstrings'],
    equipment: ['bodyweight'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Stand tall in an open space with hands on hips.\n'
        '2. Step forward into a lunge, lowering until both knees reach 90 degrees.\n'
        '3. Drive through your front heel and bring your back foot forward.\n'
        '4. Step straight into the next lunge without pausing.\n'
        '5. Continue alternating legs as you move forward.',
    tips: 'Take shorter steps if your balance wavers; control beats stride length.',
  ),
  CatalogExercise(
    id: 'romanian_deadlift',
    name: 'Romanian Deadlift',
    muscles: ['hamstrings', 'glutes', 'back'],
    equipment: ['dumbbell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Stand with feet hip-width apart, dumbbells in front of your thighs.\n'
        '2. Hinge at your hips, pushing your glutes back while keeping your back flat.\n'
        '3. Slide the weights down your legs until you feel a deep hamstring stretch.\n'
        '4. Keep a soft bend in your knees throughout.\n'
        '5. Drive your hips forward to stand back up, squeezing your glutes.',
    tips: 'The hips travel back, not down; your shins stay nearly vertical.',
  ),
  CatalogExercise(
    id: 'dumbbell_deadlift',
    name: 'Dumbbell Deadlift',
    muscles: ['glutes', 'hamstrings', 'back'],
    equipment: ['dumbbell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Stand with feet hip-width apart, dumbbells on the floor outside your feet.\n'
        '2. Hinge at your hips and bend your knees to grip the weights.\n'
        '3. Brace your core and keep your back flat and chest up.\n'
        '4. Drive through your heels to stand tall, squeezing your glutes.\n'
        '5. Lower the weights back to the floor with the same flat-back hinge.',
    tips: 'Push the floor away from you rather than pulling the weight up.',
  ),
  CatalogExercise(
    id: 'glute_bridge',
    name: 'Glute Bridge',
    muscles: ['glutes', 'hamstrings', 'core'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Lie on your back with knees bent and feet flat on the floor.\n'
        '2. Rest your arms at your sides, palms down.\n'
        '3. Press through your heels to lift your hips until knees, hips, and shoulders align.\n'
        '4. Squeeze your glutes hard at the top for two seconds.\n'
        '5. Lower your hips slowly back to the floor.',
    tips: 'Keep your ribs down so your lower back does not arch.',
  ),
  CatalogExercise(
    id: 'hip_thrust',
    name: 'Hip Thrust',
    muscles: ['glutes', 'hamstrings'],
    equipment: ['bench', 'dumbbell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Sit on the floor with your upper back against a bench and a dumbbell on your hips.\n'
        '2. Plant your feet flat, knees bent, and hold the weight in place.\n'
        '3. Drive through your heels to lift your hips until your body forms a straight line.\n'
        '4. Squeeze your glutes for two seconds at the top.\n'
        '5. Lower your hips slowly back down.',
    tips: 'Tuck your chin so your gaze stays on the wall ahead of you.',
  ),
  CatalogExercise(
    id: 'standing_calf_raise',
    name: 'Standing Calf Raise',
    muscles: ['calves'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Stand tall with feet hip-width apart, holding a wall or chair for balance if needed.\n'
        '2. Press through the balls of your feet to rise onto your toes.\n'
        '3. Pause for one second at the top.\n'
        '4. Lower your heels slowly back to the floor.\n'
        '5. Repeat without bouncing at the bottom.',
    tips: 'Pause at the top of every rep to remove momentum.',
  ),
  CatalogExercise(
    id: 'plank',
    name: 'Plank',
    muscles: ['core', 'shoulders'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Start face down, then lift onto your forearms and toes.\n'
        '2. Keep your elbows under your shoulders and body in a straight line.\n'
        '3. Brace your core and squeeze your glutes.\n'
        '4. Breathe steadily without letting your hips sag or pike.\n'
        '5. Hold for the target time, then lower down.',
    tips: 'Push the floor away with your forearms to engage your whole core.',
  ),
  CatalogExercise(
    id: 'side_plank',
    name: 'Side Plank',
    muscles: ['core', 'shoulders'],
    equipment: ['bodyweight'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Lie on your side with your forearm on the floor, elbow under your shoulder.\n'
        '2. Stack your feet and lift your hips off the floor.\n'
        '3. Keep your body in a straight line from head to feet.\n'
        '4. Brace your core and breathe steadily.\n'
        '5. Hold for the target time, then switch sides.',
    tips: 'Drop your bottom knee to the floor to make it easier.',
  ),
  CatalogExercise(
    id: 'dead_bug',
    name: 'Dead Bug',
    muscles: ['core'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Lie on your back with arms reaching toward the ceiling and knees bent at 90 degrees.\n'
        '2. Press your lower back into the floor.\n'
        '3. Slowly extend your right arm overhead and your left leg straight out.\n'
        '4. Return to the start without letting your back arch.\n'
        '5. Alternate sides for the target reps.',
    tips: 'Move slowly; the challenge is keeping your back pinned down.',
  ),
  CatalogExercise(
    id: 'bicycle_crunch',
    name: 'Bicycle Crunch',
    muscles: ['core'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Lie on your back with hands lightly behind your head.\n'
        '2. Lift your shoulders off the floor and bring your knees to 90 degrees.\n'
        '3. Twist to bring your right elbow toward your left knee while extending the right leg.\n'
        '4. Switch sides in a smooth pedaling motion.\n'
        '5. Keep your lower back pressed into the floor throughout.',
    tips: 'Do not pull on your neck; let your abs do the twisting.',
  ),
  CatalogExercise(
    id: 'russian_twist',
    name: 'Russian Twist',
    muscles: ['core'],
    equipment: ['dumbbell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Sit on the floor with knees bent and heels lightly touching the ground.\n'
        '2. Lean back slightly and hold a dumbbell at your chest.\n'
        '3. Twist your torso to one side, bringing the weight toward the floor.\n'
        '4. Return through center and twist to the other side.\n'
        '5. Keep your spine long and movement controlled.',
    tips: 'Lift your heels off the floor to make it harder.',
  ),
  CatalogExercise(
    id: 'mountain_climbers',
    name: 'Mountain Climbers',
    muscles: ['core', 'shoulders', 'quadriceps'],
    equipment: ['bodyweight'],
    difficulty: 'intermediate',
    type: 'cardio',
    instructions:
        '1. Start in a high plank with hands under your shoulders.\n'
        '2. Brace your core and keep your hips level.\n'
        '3. Drive your right knee toward your chest.\n'
        '4. Quickly switch, driving the left knee in as the right leg extends back.\n'
        '5. Continue alternating at a steady pace for the target time.',
    tips: 'Keep your hips low; speed matters less than a flat back.',
  ),
  CatalogExercise(
    id: 'burpee',
    name: 'Burpee',
    muscles: ['full body'],
    equipment: ['bodyweight'],
    difficulty: 'advanced',
    type: 'cardio',
    instructions:
        '1. From standing, drop into a squat and place your hands on the floor.\n'
        '2. Jump your feet back into a high plank.\n'
        '3. Do one push-up, keeping your body straight.\n'
        '4. Jump your feet back to your hands.\n'
        '5. Explode upward into a jump, reaching your arms overhead.',
    tips: 'Step back instead of jumping to scale the intensity down.',
  ),
  CatalogExercise(
    id: 'kettlebell_swing',
    name: 'Kettlebell Swing',
    muscles: ['glutes', 'hamstrings', 'back'],
    equipment: ['kettlebell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Stand with feet wider than shoulder width, kettlebell on the floor in front of you.\n'
        '2. Hinge at your hips and grip the handle with both hands.\n'
        '3. Hike the bell back between your legs, then snap your hips forward.\n'
        '4. Let the bell float to chest height, arms straight but relaxed.\n'
        '5. Guide it back down into the next hinge and repeat.',
    tips: 'The power comes from the hip snap, not from lifting with your arms.',
  ),
  CatalogExercise(
    id: 'kettlebell_goblet_squat',
    name: 'Kettlebell Goblet Squat',
    muscles: ['quadriceps', 'glutes', 'core'],
    equipment: ['kettlebell'],
    difficulty: 'beginner',
    type: 'strength',
    instructions:
        '1. Hold a kettlebell by its horns at chest height.\n'
        '2. Stand with feet slightly wider than shoulder width, toes out.\n'
        '3. Push your hips back and lower into a squat.\n'
        '4. Keep your chest up and elbows tracking inside your knees.\n'
        '5. Drive through your heels to stand.',
    tips: 'Pause at the bottom for a beat to build control.',
  ),
  CatalogExercise(
    id: 'kettlebell_row',
    name: 'Single-Arm Kettlebell Row',
    muscles: ['back', 'biceps'],
    equipment: ['kettlebell'],
    difficulty: 'intermediate',
    type: 'strength',
    instructions:
        '1. Place one hand on a bench or your thigh and hinge forward with a flat back.\n'
        '2. Hold the kettlebell in the free hand, arm hanging straight.\n'
        '3. Row the bell toward your hip, squeezing your shoulder blade.\n'
        '4. Lower it slowly to full extension.\n'
        '5. Complete all reps, then switch sides.',
    tips: 'Keep the bell close to your body on the way up.',
  ),
  CatalogExercise(
    id: 'jumping_jacks',
    name: 'Jumping Jacks',
    muscles: ['full body'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'cardio',
    instructions:
        '1. Stand with feet together and arms at your sides.\n'
        '2. Jump your feet out wide while raising your arms overhead.\n'
        '3. Land softly with knees slightly bent.\n'
        '4. Jump back to the start position, lowering your arms.\n'
        '5. Continue at a steady, comfortable rhythm.',
    tips: 'Step side to side instead of jumping for a low-impact version.',
  ),
  CatalogExercise(
    id: 'high_knees',
    name: 'High Knees',
    muscles: ['quadriceps', 'calves', 'core'],
    equipment: ['bodyweight'],
    difficulty: 'intermediate',
    type: 'cardio',
    instructions:
        '1. Stand tall with feet hip-width apart.\n'
        '2. Drive your right knee up toward hip height.\n'
        '3. Quickly switch legs as you bounce lightly on the balls of your feet.\n'
        '4. Pump your arms in opposition to your legs.\n'
        '5. Continue alternating for the target time.',
    tips: 'Land on the balls of your feet to stay springy and quiet.',
  ),
  CatalogExercise(
    id: 'brisk_marching',
    name: 'Brisk Marching in Place',
    muscles: ['full body'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'cardio',
    instructions:
        '1. Stand tall with feet hip-width apart and arms at your sides.\n'
        '2. March in place, lifting each knee toward hip height.\n'
        '3. Swing your arms naturally in opposition.\n'
        '4. Keep your chest up and core lightly braced.\n'
        '5. Maintain a brisk, steady pace for the target time.',
    tips: 'Add a small bounce between steps to raise your heart rate.',
  ),
  CatalogExercise(
    id: 'skater_hops',
    name: 'Skater Hops',
    muscles: ['glutes', 'quadriceps', 'calves'],
    equipment: ['bodyweight'],
    difficulty: 'intermediate',
    type: 'cardio',
    instructions:
        '1. Stand with feet together and a slight bend in your knees.\n'
        '2. Hop laterally to the right, landing on your right foot.\n'
        '3. Swing your left foot behind you and touch the floor lightly for balance.\n'
        '4. Immediately hop to the left side and repeat.\n'
        '5. Continue side to side with a smooth, athletic rhythm.',
    tips: 'Land softly on the ball of your foot with a bent knee.',
  ),
  CatalogExercise(
    id: 'butt_kicks',
    name: 'Butt Kicks',
    muscles: ['hamstrings', 'calves'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'cardio',
    instructions:
        '1. Stand tall with feet hip-width apart.\n'
        '2. Kick your right heel up toward your glutes.\n'
        '3. Quickly alternate, kicking your left heel up.\n'
        '4. Stay on the balls of your feet with a light bounce.\n'
        '5. Pump your arms and continue at a steady pace.',
    tips: 'Keep your knees pointing down, not flaring forward.',
  ),
  CatalogExercise(
    id: 'shadow_boxing',
    name: 'Shadow Boxing',
    muscles: ['shoulders', 'core'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'cardio',
    instructions:
        '1. Stand in a staggered stance with hands up in fists.\n'
        '2. Throw a jab with your lead hand, rotating your fist at extension.\n'
        '3. Follow with a cross from your rear hand, pivoting your back foot.\n'
        '4. Add hooks and uppercuts, staying light on your feet.\n'
        '5. Keep moving and breathing for the target time.',
    tips: 'Snap each punch out and back; never lock your elbows.',
  ),
  CatalogExercise(
    id: 'jump_squat',
    name: 'Jump Squat',
    muscles: ['quadriceps', 'glutes', 'calves'],
    equipment: ['bodyweight'],
    difficulty: 'advanced',
    type: 'cardio',
    instructions:
        '1. Stand with feet shoulder-width apart.\n'
        '2. Lower into a squat with chest up and knees tracking over toes.\n'
        '3. Explode upward, jumping as high as you can.\n'
        '4. Land softly with bent knees, sinking straight into the next squat.\n'
        '5. Repeat with control, resting as needed.',
    tips: 'Land quietly; loud landings mean stiff joints.',
  ),
  CatalogExercise(
    id: 'cat_cow',
    name: 'Cat-Cow',
    muscles: ['back', 'core'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'mobility',
    instructions:
        '1. Start on all fours with hands under shoulders and knees under hips.\n'
        '2. Inhale: drop your belly, lift your tailbone and chest for cow pose.\n'
        '3. Exhale: round your back, tuck your chin and tailbone for cat pose.\n'
        '4. Move slowly between the two positions with your breath.\n'
        '5. Repeat for the target number of breath cycles.',
    tips: 'Move one vertebra at a time rather than hinging at one spot.',
  ),
  CatalogExercise(
    id: 'thoracic_rotation',
    name: 'Thoracic Rotation',
    muscles: ['back', 'core'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'mobility',
    instructions:
        '1. Start on all fours with hands under shoulders.\n'
        '2. Place your right hand behind your head.\n'
        '3. Rotate your right elbow up toward the ceiling, following it with your eyes.\n'
        '4. Pause briefly at the top of the rotation.\n'
        '5. Return slowly, then repeat on the other side.',
    tips: 'Keep your hips square; the twist comes from your mid-back.',
  ),
  CatalogExercise(
    id: 'hip_flexor_stretch',
    name: 'Kneeling Hip Flexor Stretch',
    muscles: ['quadriceps', 'glutes'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'mobility',
    instructions:
        '1. Kneel on one knee with the other foot flat in front, both knees at 90 degrees.\n'
        '2. Tuck your pelvis slightly under, as if pulling your belt buckle up.\n'
        '3. Shift your weight gently forward until you feel a stretch in the front of the back hip.\n'
        '4. Raise the same-side arm overhead for a deeper stretch.\n'
        '5. Hold, breathe, then switch sides.',
    tips: 'Squeeze the glute of the back leg to deepen the stretch.',
  ),
  CatalogExercise(
    id: 'ninety_ninety_hip_switch',
    name: '90/90 Hip Switch',
    muscles: ['glutes'],
    equipment: ['mat'],
    difficulty: 'intermediate',
    type: 'mobility',
    instructions:
        '1. Sit on the floor with both knees bent at 90 degrees, one leg forward and one to the side.\n'
        '2. Keep your chest tall and hands on the floor for support.\n'
        '3. Lift both knees and rotate them to switch sides.\n'
        '4. Settle into the mirrored 90/90 position.\n'
        '5. Continue switching sides with control.',
    tips: 'Keep both sit bones heavy; avoid hiking one hip up.',
  ),
  CatalogExercise(
    id: 'band_shoulder_dislocates',
    name: 'Band Shoulder Dislocates',
    muscles: ['shoulders', 'chest'],
    equipment: ['resistance band'],
    difficulty: 'beginner',
    type: 'mobility',
    instructions:
        '1. Hold a resistance band in front of you with a wide grip.\n'
        '2. Keeping your arms straight, slowly raise the band overhead.\n'
        '3. Continue behind your head until the band reaches your lower back.\n'
        '4. Reverse the path back to the front.\n'
        '5. Repeat slowly, widening your grip if you feel pinching.',
    tips: 'Keep your ribs down; do not arch your back to cheat the range.',
  ),
  CatalogExercise(
    id: 'ankle_circles',
    name: 'Ankle Circles',
    muscles: ['calves'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'mobility',
    instructions:
        '1. Sit or stand and lift one foot slightly off the floor.\n'
        '2. Slowly draw large circles in the air with your toes.\n'
        '3. Complete the target circles in one direction.\n'
        '4. Reverse and circle the other direction.\n'
        '5. Switch feet and repeat.',
    tips: 'Make the circles as big as possible without moving your knee.',
  ),
  CatalogExercise(
    id: 'standing_quad_stretch',
    name: 'Standing Quad Stretch',
    muscles: ['quadriceps'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Stand tall and hold a wall or chair for balance.\n'
        '2. Bend one knee and grab your ankle or pant leg behind you.\n'
        '3. Gently pull your heel toward your glute.\n'
        '4. Keep your knees together and hips tucked under.\n'
        '5. Hold for 20 to 30 seconds, then switch legs.',
    tips: 'Stand tall; leaning forward shortens the stretch.',
  ),
  CatalogExercise(
    id: 'standing_hamstring_fold',
    name: 'Standing Hamstring Fold',
    muscles: ['hamstrings'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Stand with feet hip-width apart.\n'
        '2. Hinge at your hips and fold forward, letting your arms hang.\n'
        '3. Keep a soft bend in your knees.\n'
        '4. Let your head and neck relax completely.\n'
        '5. Hold for 20 to 30 seconds, breathing deeply.',
    tips: 'Shift your weight slightly forward into the balls of your feet.',
  ),
  CatalogExercise(
    id: 'chest_doorway_stretch',
    name: 'Doorway Chest Stretch',
    muscles: ['chest', 'shoulders'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Stand in a doorway and place your forearms on the frame at shoulder height.\n'
        '2. Step one foot through the doorway into a staggered stance.\n'
        '3. Lean gently forward until you feel a stretch across your chest.\n'
        '4. Hold for 20 to 30 seconds while breathing deeply.\n'
        '5. Try a slightly higher or lower arm position to hit different angles.',
    tips: 'Keep your shoulders down away from your ears.',
  ),
  CatalogExercise(
    id: 'childs_pose',
    name: "Child's Pose",
    muscles: ['back', 'shoulders'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Kneel on a mat with knees wide and big toes touching.\n'
        '2. Sit your hips back toward your heels.\n'
        '3. Walk your hands forward and lower your forehead to the floor.\n'
        '4. Let your chest sink between your thighs.\n'
        '5. Hold for 30 seconds or longer, breathing into your back.',
    tips: 'Spread your fingers wide and reach long through your fingertips.',
  ),
  CatalogExercise(
    id: 'cobra_pose',
    name: 'Cobra Pose',
    muscles: ['back', 'core'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Lie face down with hands under your shoulders.\n'
        '2. Press the tops of your feet into the floor.\n'
        '3. Straighten your arms to lift your chest, keeping your hips on the floor.\n'
        '4. Roll your shoulders back and look slightly upward.\n'
        '5. Hold for 20 to 30 seconds, breathing deeply.',
    tips: 'Keep a little bend in your elbows; height is not the goal.',
  ),
  CatalogExercise(
    id: 'neck_rolls',
    name: 'Neck Rolls',
    muscles: ['shoulders'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Sit or stand tall with shoulders relaxed.\n'
        '2. Slowly drop your chin toward your chest.\n'
        '3. Roll your head gently to one side, bringing your ear toward your shoulder.\n'
        '4. Continue rolling your head in a slow half-circle to the other side.\n'
        '5. Reverse direction and repeat, keeping movements smooth.',
    tips: 'Move slowly and skip any position that causes sharp pain.',
  ),
  CatalogExercise(
    id: 'wall_calf_stretch',
    name: 'Wall Calf Stretch',
    muscles: ['calves'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Face a wall and place both hands on it at shoulder height.\n'
        '2. Step one foot back, keeping that leg straight and heel on the floor.\n'
        '3. Bend your front knee and lean toward the wall.\n'
        '4. Hold for 20 to 30 seconds, feeling the stretch in your back calf.\n'
        '5. Bend the back knee slightly to shift the stretch deeper, then switch legs.',
    tips: 'Keep your back heel glued to the floor the entire time.',
  ),
  CatalogExercise(
    id: 'figure_four_glute_stretch',
    name: 'Figure-4 Glute Stretch',
    muscles: ['glutes'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Lie on your back with both knees bent and feet flat.\n'
        '2. Cross your right ankle over your left knee.\n'
        '3. Thread your hands behind your left thigh and gently pull toward you.\n'
        '4. Keep your head and shoulders relaxed on the floor.\n'
        '5. Hold for 20 to 30 seconds, then switch sides.',
    tips: 'Flex the top foot to protect your knee.',
  ),
  CatalogExercise(
    id: 'seated_spinal_twist',
    name: 'Seated Spinal Twist',
    muscles: ['back', 'core'],
    equipment: ['mat'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Sit tall with both legs extended in front of you.\n'
        '2. Bend your right knee and cross it over your left leg.\n'
        '3. Place your left elbow outside your right knee.\n'
        '4. Twist your torso to the right, looking over your right shoulder.\n'
        '5. Hold for 20 to 30 seconds, then switch sides.',
    tips: 'Grow tall through your spine before each twist.',
  ),
  CatalogExercise(
    id: 'wrist_flexor_stretch',
    name: 'Wrist Flexor Stretch',
    muscles: ['forearms'],
    equipment: ['bodyweight'],
    difficulty: 'beginner',
    type: 'stretch',
    instructions:
        '1. Extend one arm in front of you, palm facing up.\n'
        '2. With your other hand, gently press your fingers down and back.\n'
        '3. Hold for 15 to 20 seconds, feeling the stretch in your forearm.\n'
        '4. Flip your palm to face down and press the back of your hand for the extensors.\n'
        '5. Repeat on the other wrist.',
    tips: 'Keep the stretch gentle; wrists respond to consistency, not force.',
  ),
];
