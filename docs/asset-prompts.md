# Tendle Asset Prompts

## 1. 브랜드 시스템

Tendle의 시각 언어는 "중독성 있는 규칙을 즉시 이해시키는 미니멀 퍼즐 아이콘"을 목표로 한다. 그래픽 장식보다 17x10 숫자 격자, 합=10, 데일리 챌린지, 봇 점수라는 아이디어가 먼저 읽혀야 한다. 전체 톤은 kpop-heardle의 인디 포트폴리오 결처럼 작고 선명한 앱 경험을 지향하되, Tendle은 음악적 화려함 대신 조용한 계산감과 손맛을 전면에 둔다.

### 컬러 팔레트

라이트 모드는 종이 같은 표면 위에 선명한 그린을 두고, 다크 모드는 흑청색 표면 위에 민트 그린을 올린다. primary는 앱 아이콘과 주요 CTA에 사용하고, success는 제거 성공, danger는 시간 종료/패배, muted는 비활성 숫자와 보조 텍스트에 사용한다.

```text
Light
primary  #2FBF71
surface  #F7F4EA
ink      #18221D
success  #20A866
danger   #E4574F
muted    #8A918B

Dark
primary  #6EE7A8
surface  #101914
ink      #F1F5EE
success  #45D483
danger   #FF6B63
muted    #8B9A91
```

### 타이포그래피

iOS 시스템 폰트를 사용한다. 숫자 보드와 점수는 SF Pro Rounded 계열의 느낌이 나도록 rounded design을 우선하고, 본문은 기본 SF Pro Text를 사용한다.

```text
Display  System Rounded / Semibold / 34-44pt / daily score, result headline
Title    System Rounded / Semibold / 22-28pt / screen title, section title
Body     System / Regular / 16-17pt / settings, explanations, list rows
Caption  System / Medium / 12-13pt / timer labels, bot score labels, metadata
```

### 코너 라운딩 스케일

```text
radius-0   0pt   / hard grid edge, icon export frame
radius-1   4pt   / tiny digit cells, mini badges
radius-2   8pt   / buttons, board cells, repeated cards
radius-3   12pt  / bottom sheets, result panels
radius-4   18pt  / launch illustration blocks
radius-pill 999pt / timer capsule, segmented controls
```

## 2. 아이콘 디자인 컨셉 후보

### 후보 A: Ten Tile Loop

- 시각적 핵심 모티프: 중앙에 둥근 사각형 숫자 타일 4개가 2x2로 모이고, 선택된 직사각형 테두리가 이들을 감싸며 "합=10을 찾아 지우는 손맛"을 즉시 보여준다. 10이라는 규칙이 앱의 핵심이므로 가장 직접적인 브랜드 기호가 된다.
- 1차 컬러: `#2FBF71`
- 2차 컬러: `#F7F4EA`
- 사각형/숫자/합=10 모티프: 네 개의 작은 타일에는 텍스트 숫자를 넣지 않고, 점 개수 패턴 1+2+3+4를 매우 단순한 핍으로 배치해 합이 10임을 암시한다. 바깥 선택 사각형은 사과게임의 드래그 영역을 뜻한다.
- iOS 1024x1024 구도: 배경은 surface 전체 면. 중앙 visual mass는 약 220x220pt 기준의 큰 선택 사각형을 1024 캔버스 중앙에 배치한다. 실제 픽셀 기준으로는 x=244, y=244, w=536, h=536 안에 모든 요소를 넣고, 네 타일은 각 204x204, gap 36, radius 64로 구성한다. primary 선택 테두리는 42px 두께로 처리한다.
- 40x40 식별성: 5/5. 2x2 타일과 단일 선택 테두리만 남아도 퍼즐 앱 아이콘으로 읽힌다.

### 후보 B: Bot Benchmark Split

- 시각적 핵심 모티프: 왼쪽은 플레이어가 지운 타일, 오른쪽은 봇 점수를 뜻하는 작은 회로형 타일로 나뉜다. Tendle의 차별점인 "오늘의 봇 점수"를 아이콘 레벨에서 드러낸다.
- 1차 컬러: `#6EE7A8`
- 2차 컬러: `#101914`
- 사각형/숫자/합=10 모티프: 중앙의 세로 분할선 양쪽에 각각 5개씩 작은 칸을 두어 총 10칸을 만든다. 오른쪽 칸 일부는 작은 원형 노드로 연결해 솔버 봇의 계산감을 표현한다.
- iOS 1024x1024 구도: 다크 surface 배경 위에 180pt visual mass 가이드를 기준으로 폭 500px, 높이 560px의 둥근 직사각형 보드 실루엣을 중앙 배치한다. 왼쪽 5칸은 solid primary, 오른쪽 5칸은 primary outline으로 두어 대결 구도를 만든다.
- 40x40 식별성: 4/5. 봇 트위스트는 강하지만 작은 크기에서 회로 노드는 일부 사라지고 단순 분할 보드로 읽힐 수 있다.

### 후보 C: Daily Ten Stamp

- 시각적 핵심 모티프: 달력 한 장 안에 10개의 둥근 미니 타일이 체크 모양으로 모이는 데일리 퍼즐 스탬프. 매일 한 판이라는 습관성과 합=10 규칙을 함께 전달한다.
- 1차 컬러: `#2FBF71`
- 2차 컬러: `#F7F4EA`
- 사각형/숫자/합=10 모티프: 달력 본문에는 10개의 작은 사각 칩을 3-4-3 배열로 놓고, 선택 성공을 뜻하는 부드러운 체크 흐름으로 연결한다. 숫자 자체는 쓰지 않는다.
- iOS 1024x1024 구도: surface 배경 위에 x=252, y=214, w=520, h=596의 둥근 달력 블록을 배치한다. 상단 바는 primary solid, 본문은 primary outline 칩. visual mass는 180pt보다 약간 큰 210pt로 잡아 작은 사이즈에서 달력 윤곽을 유지한다.
- 40x40 식별성: 3/5. 데일리 게임 정체성은 좋지만 사과게임의 직사각형 선택 규칙은 후보 A보다 약하다.

## 3. 권장 후보

권장안은 **후보 A: Ten Tile Loop**이다.

이유는 세 가지다. 첫째, Tendle의 가장 강한 기억 단위는 "숫자들을 사각형으로 묶어 합 10을 만든다"는 규칙이며, 후보 A는 이 규칙을 장식 없이 바로 시각화한다. 둘째, 40x40 홈 화면에서도 2x2 타일과 선택 테두리가 남아 식별성이 가장 높다. 셋째, 봇 점수는 제품의 트위스트지만 아이콘의 첫 임무는 게임 규칙을 각인시키는 것이므로, 봇은 앱 내부 결과 화면과 마이크로 일러스트에서 보조 모티프로 쓰는 편이 더 명확하다.

## 4. 이미지 생성 프롬프트

### App Icon: Selected Direction

```text
app icon, 1024x1024, no text, square corners (iOS will mask), flat minimalist, two-tone palette #2FBF71 #F7F4EA, motif: four soft rounded number tiles arranged in a centered 2x2 square, each tile uses tiny dot pips instead of numerals to imply 1 plus 2 plus 3 plus 4 equals 10, a single thick rounded rectangular selection outline wraps the four tiles like a drag-selected puzzle region, balanced composition centered on 180/220 mass grid, calm indie daily puzzle feel, soft rounded geometry, no shadows, no gradients beyond a single soft duotone, no letters, no words, no photorealism
```

### Variation 1: Dark Mint

```text
app icon, 1024x1024, no text, square corners (iOS will mask), flat minimalist, two-tone palette #6EE7A8 #101914, motif: four soft rounded puzzle tiles in a centered 2x2 arrangement, subtle dot pips on the tiles suggest a sum of ten without using written numbers, one thick rounded rectangular selection frame surrounds the tile group, balanced composition centered on 180/220 mass grid, crisp daily puzzle identity, high contrast for small iOS icon sizes, no shadows, no gradients beyond a single soft duotone, no letters, no words, no 3D
```

### Variation 2: Success Stamp

```text
app icon, 1024x1024, no text, square corners (iOS will mask), flat minimalist, two-tone palette #20A866 #F7F4EA, motif: a compact 2x2 set of rounded square tiles being cleared by a simple rounded rectangle selection path, tiny pips across the four tiles imply 10 as a completed sum, centered composition with visual mass inside a 220 point guide, slightly softer corners and a satisfying solved-puzzle stamp feeling, no shadows, no gradients beyond a single soft duotone, no letters, no numerals, no decorative confetti
```

## 5. 부가 자산 프롬프트

### Launch Screen

```text
iOS launch screen illustration, 1290x2796 portrait, flat minimalist, two-tone palette #2FBF71 #F7F4EA with ink accent #18221D used sparingly, no text, a quiet centered 17 by 10 puzzle grid made of soft rounded square cells, several cells are gently highlighted inside one rounded rectangular selection region that implies sum-to-10 gameplay, large empty breathing space around the board, indie daily puzzle mood, clean system-app feel, no shadows, no heavy gradients, no characters, no photorealism
```

### Empty-State Illustration: Before Today's Board Arrives

```text
empty-state illustration for a daily iOS puzzle game, 1024x768, flat minimalist, two-tone palette #2FBF71 #F7F4EA with muted accent #8A918B, no text, a small rounded calendar tile sits behind a simplified puzzle grid, one soft selection rectangle is waiting over blank rounded cells, visual feeling of a daily board about to appear, centered but light composition with generous whitespace, no shadows, no gradients beyond a soft duotone, no characters, no clocks with numbers, no letters
```

### Result Win Micro Illustration

```text
micro illustration for puzzle result win state, 768x512, flat minimalist, two-tone palette #20A866 #F7F4EA with ink accent #18221D, no text, a compact group of rounded square tiles disappears into a clean check-shaped path made from small square pips, include a tiny secondary bot benchmark tile as an outlined rounded square beside the cleared group, celebratory but restrained, no confetti overload, no shadows, no gradients beyond a soft duotone, no numerals, no words
```

### Result Lose Micro Illustration

```text
micro illustration for puzzle result lose state, 768x512, flat minimalist, two-tone palette #E4574F #F7F4EA with muted accent #8A918B, no text, a few rounded square tiles remain inside an unfinished selection rectangle, a small outlined bot benchmark tile sits slightly higher to imply the benchmark score, calm and non-punitive daily puzzle result mood, no sad characters, no harsh warning signs, no shadows, no gradients beyond a soft duotone, no numerals, no words
```

## 6. 재현성 노트

### 출력 파일명 규칙

```text
app icon selected       tendle-app-icon-ten-tile-loop-r01.png
app icon variation 1    tendle-app-icon-dark-mint-r01.png
app icon variation 2    tendle-app-icon-success-stamp-r01.png
launch screen           tendle-launch-grid-r01.png
empty state             tendle-empty-daily-board-r01.png
result win              tendle-result-win-clear-r01.png
result lose             tendle-result-lose-benchmark-r01.png
```

리비전 번호는 `r01`, `r02`, `r03`처럼 두 자리 숫자로 증가시킨다. 같은 프롬프트에서 seed나 모델만 바꾼 경우도 새 파일로 저장하고 리비전 노트에 변경점을 적는다.

### 리비전 노트 양식

```text
Asset:
Filename:
Date:
Generator:
Prompt version:
Palette:
Composition notes:
Small-size check:
Decision:
Next revision instruction:
```

### r01 기준 노트

```text
Asset: App icon
Filename: tendle-app-icon-ten-tile-loop-r01.png
Date: 2026-05-17
Generator: Codex image generation or DALL-E
Prompt version: App Icon Selected Direction
Palette: #2FBF71 / #F7F4EA
Composition notes: 2x2 tile group centered, single rounded selection rectangle, no written numerals
Small-size check: must remain recognizable at 40x40 as a grid-selection puzzle icon
Decision: use as primary AppIcon candidate if tile silhouette and selection frame are readable
Next revision instruction: increase tile gap and simplify pips if 40x40 preview feels crowded
```

## 7. 캐릭터 일러스트 (Layer 2 — 8세 그림체)

Layer 2는 §11.1의 미니멀 UI 레이어와 분리된 감정/순간 레이어다. 앱의 버튼, 보드, 아이콘은 Layer 1이 담당하고, 캐릭터 일러스트는 스플래시, 빈 상태, 로딩, 결과, 마일스톤처럼 아이가 "나를 응원한다"고 느끼는 장면에만 사용한다. 모든 장면에서 지율과 은찬은 협동하는 친구로 등장하며, 드래곤/거미/뱀은 둥글고 귀여운 동물 친구처럼 표현한다.

### 7.0 캐릭터 컬러 팔레트

Layer 2는 크레용, 마커, 색연필 질감이 보이도록 따뜻하고 다양한 색을 쓴다. 색은 정확한 벡터 팔레트가 아니라 생성 방향을 고정하기 위한 기준이다.

```text
Jiyul hair             warm dark brown #4A2C24
Jiyul skin             warm peach #F3B796
Jiyul outfit main      sunny coral #F26C5B
Jiyul outfit accent    butter yellow #FFD76A
Jiyul shoes/details    berry pink #D94C8A

Eunchan hair           soft black brown #2E2522
Eunchan skin           warm peach #F0B28F
Eunchan outfit main    sky blue #4FA7E8
Eunchan outfit accent  leaf green #54B96F
Eunchan shoes/details  warm navy #344B7A

Friendly dragon        mint green #75D99B with yellow belly #FFE08A
Friendly spider        lavender purple #9B7BE8 with teal socks #5BC7C8
Friendly snake         apple green #7BCF5A with coral spots #F47A6B

Shared warmth          cream paper #FFF1D6, crayon red #E84B45,
                       marker orange #FF9A3D, soft violet #8B6FE8
```

공통 프롬프트 조건:

```text
in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, no text, no logos, no photorealism, no anime style
```

### 7.1 캐릭터 시트 (Character sheets)

#### Jiyul reference sheet

출력 파일명: `tendle-character-jiyul-sheet-r01.png`

```text
character reference sheet, 2048x1536, Jiyul only, long-haired cheerful girl protagonist for a children's puzzle app, show front view, side view, three-quarter view, and expressive face variations: curious, proud, focused, surprised, giggling, include small pose thumbnails where she points at puzzle tiles, holds a calendar tile, and waves to friendly creature companions, warm dark brown long straight hair, sunny coral outfit with butter yellow accents and berry pink details, keep proportions childlike and simple, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no labels, no logos, no photorealism, no anime style
```

#### Eunchan reference sheet

출력 파일명: `tendle-character-eunchan-sheet-r01.png`

```text
character reference sheet, 2048x1536, Eunchan only, friendly companion boy for a children's puzzle app, show front view, side view, three-quarter view, and expressive face variations: cheering, thinking, amazed, determined, laughing, include small pose thumbnails where he claps, reaches toward a puzzle tile, sits beside Jiyul, and celebrates a shared win, soft black brown hair, sky blue outfit with leaf green accents and warm navy details, cooperative friend energy, never competitive, keep proportions childlike and simple, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no labels, no logos, no photorealism, no anime style
```

#### 친구 동물들 reference sheet

출력 파일명: `tendle-character-creature-friends-sheet-r01.png`

```text
creature companion reference sheet, 2048x1536, three friendly magical animal friends for a children's puzzle app: a mint green rounded dragon with yellow belly, tiny wings, soft horns, big smile; a lavender purple cute spider with eight simple rounded legs, teal sock-like feet, big smile, no scary features; an apple green playful snake with coral spots, rounded head, smiling face, gentle curled poses, show each creature front view, side view, happy action pose, and tiny sticker pose, childlike simple shapes, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no labels, no logos, no photorealism, no anime style
```

### 7.2 스플래시 / 런치

#### Splash screen: Jiyul + Eunchan + giant 10 tile

출력 파일명: `tendle-splash-jiyul-eunchan-r01.png`

```text
iOS splash screen illustration, 1290x2796 portrait, Jiyul and Eunchan reaching together toward a giant friendly puzzle tile representing 10 with ten big crayon dots, Jiyul is a long-haired girl in sunny coral and butter yellow, Eunchan is a boy in sky blue and leaf green, they are smiling and playing together as friends, a cute rounded mint green dragon coils gently above them in a playful title-like arc that suggests the Tendle title without drawing any letters, cream paper background with scattered warm crayon puzzle shapes, centered vertical composition with safe empty space near top and bottom for app UI, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no numerals, no logos, no photorealism, no anime style
```

### 7.3 홈 (HomeView empty-state)

#### HomeView empty-state: today's board

출력 파일명: `tendle-home-empty-jiyul-eunchan-calendar-r01.png`

```text
empty-state illustration for a children's daily puzzle app, 1024x768, Jiyul and Eunchan sitting cross-legged together on a cream paper floor, Jiyul is a long-haired girl holding today's blank calendar tile with no writing, Eunchan sits beside her smiling and pointing at soft puzzle squares, a cute rounded lavender spider companion peeks from behind the calendar tile with a friendly smile, warm crayon puzzle pieces scattered lightly around them, balanced centered composition with open space above for app content, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no logos, no photorealism, no anime style
```

### 7.4 게임 로딩 / 솔버 초기화

#### Solver loading: scroll of numbers

출력 파일명: `tendle-loading-jiyul-scroll-snake-r01.png`

```text
loading illustration for a children's puzzle game, 1024x768, Jiyul reading a tiny scroll of playful number-like puzzle marks while a cute apple green snake friend is draped gently over her shoulder like a scarf, Eunchan kneels beside her looking curious and supportive, both children smiling softly as if solving together, small rounded puzzle tiles float around them, cream paper background with warm crayon marks, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no readable text, no logos, no photorealism, no anime style
```

### 7.5 결과 화면 (3종)

#### Result Win

출력 파일명: `tendle-result-win-jiyul-eunchan-dragon-r01.png`

```text
result screen illustration, win moment, 768x512, Jiyul and Eunchan high-fiving with big happy faces, Jiyul is a long-haired girl in sunny coral and butter yellow, Eunchan is a boy in sky blue and leaf green, a cute rounded mint green dragon does a happy loop overhead like a soft ribbon, small colorful crayon puzzle tiles bounce around them, celebratory but gentle, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no logos, no photorealism, no anime style
```

#### Result Close / cliffhanger

출력 파일명: `tendle-result-close-jiyul-eunchan-r01.png`

```text
result screen illustration, close cliffhanger moment, 768x512, Jiyul and Eunchan with determined encouraging faces, both leaning forward with almost-reaching hands toward a final rounded puzzle tile just out of reach, they look hopeful and ready to try again, not upset, a few warm crayon puzzle sparks around the tile, cooperative friend energy, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no logos, no photorealism, no anime style
```

#### Result Low / lose

출력 파일명: `tendle-result-low-jiyul-eunchan-spider-r01.png`

```text
result screen illustration, low score encouragement moment, 768x512, Jiyul and Eunchan shrugging warmly together with gentle smiles, no sad faces, no shame, no failure symbols, a cute rounded lavender spider companion gives a tiny thumbs-up beside them, soft scattered puzzle tiles on cream paper background, the mood says that trying again is welcome and friendly, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no logos, no photorealism, no anime style
```

### 7.6 마일스톤

#### Streak milestone

출력 파일명: `tendle-milestone-streak-jiyul-eunchan-snake-r01.png`

```text
streak milestone illustration for a children's daily puzzle app, 1024x768, Jiyul wearing a simple paper crown and smiling proudly, Eunchan clapping beside her with a happy supportive face, a cute apple green snake forms a small celebratory loop near their feet like a soft spiral, warm crayon confetti dots and rounded puzzle tiles around them, celebratory but cozy, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no logos, no photorealism, no anime style
```

### 7.7 부가 모먼트 (선택적)

#### Combo sticker

출력 파일명: `tendle-sticker-combo-creature-friends-r01.png`

```text
small transparent-background sticker illustration, 512x512, combo moment for a children's puzzle app, Jiyul and Eunchan popping into frame from the bottom edge with excited smiles while a tiny cute rounded dragon, spider, and snake stack friendly puzzle tiles together, energetic warm crayon motion lines, compact readable silhouette for in-app overlay use, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no logos, no photorealism, no anime style
```

#### App revisit welcome

출력 파일명: `tendle-welcome-back-jiyul-eunchan-r01.png`

```text
welcome back illustration for a children's daily puzzle app, 1024x768, Jiyul and Eunchan waving warmly from behind a soft rounded puzzle board, Jiyul is a long-haired girl in sunny coral and butter yellow, Eunchan is a boy in sky blue and leaf green, the friendly mint dragon peeks from one side, the lavender spider peeks from another side, and the apple green snake curls gently along the bottom edge, cream paper background with varied warm crayon colors, two children: Jiyul (long-haired girl) and Eunchan (boy), playing together as friends, in the style of an 8-year-old child's drawing, crayon and marker texture, naive perspective, expressive imperfect lines, warm, friendly, encouraging mood, creatures (dragons/spiders/snakes) drawn cute and rounded, never threatening, with smiling faces, no text, no logos, no photorealism, no anime style
```
