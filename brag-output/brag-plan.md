# Brag Plan: Web_app_infra

## What is this app?
A Terraform codebase that stands up production-grade AWS web-app infrastructure (VPC, WAF, ALB, auto-scaling EC2, RDS primary + replica, Cognito, monitoring) as three isolated environments — dev, staging, prod — from 11 reusable modules.

## The angle
"One command, three clouds." Infrastructure projects have no UI, so the terminal *is* the UI and the architecture diagram *is* the product shot. The flex is how much real, hardened AWS comes out of `terraform apply` — and that nobody ever SSHes into it.

## Hook (first 2-3 seconds)
A dark terminal. `terraform apply` types itself out, Enter clicks, and a green `Apply complete!` lands. Everything after is what that command built.

## Key moments (the middle)
- Three environment cards deal in: dev / staging / prod with their real VPC CIDRs and ASG ranges (1–2, 2–4, 2–6 servers).
- The request path lights up node by node — Route 53 → WAF → ALB → EC2 Auto Scaling → RDS — beside the project's real architecture diagram (web_app_infra.png), slowly panning.
- Security flex: "No SSH. No open ports. No key pairs." — admin access is SSM Session Manager only.

## Outro / punchline
"Web_app_infra" — "Production-grade AWS, written in Terraform." Stat row: 11 modules · 3 environments · 0 open admin ports.

## User flow worth showing
Entry: `terraform apply` in environments/dev → Key action: modules wire VPC, WAF, ALB, ASG, RDS → Result: three live, isolated environments reachable over HTTPS, admin via SSM.

## Tone
- Preset: polished
- Creative direction: quiet, confident infra flex — terminal-to-cloud
- Interpretation: restrained type, few scenes with firm holds, monospace for anything that is "code", one warm AWS-orange accent. No jokes beyond the dry "No SSH" beat.

## Format: landscape — 1920x1080
## Duration: ~21.5s

## Visual identity (from the project)
No web CSS — identity comes from the architecture diagram.
- Background: deep navy #0B1220 (tinted toward the diagram's AWS frame)
- Accent: AWS orange #FF9900 (diagram's AWS logo / AZ1 box)
- Secondary signal: diagram data-flow red #E8636B (flow arrows) — used only for the request-path line
- Success green for terminal output: #3FB950
- Text: #E8EDF5
- Display font: Montserrat 900 (embedded); Body/code font: JetBrains Mono 400/700 (embedded)
- Strongest visual element: web_app_infra.png architecture diagram

## Share copy (draft)
One `terraform apply`, three isolated AWS environments — WAF, auto-scaling EC2, RDS with a read replica, and not a single open SSH port.

## Audio direction
- Role: warm bed + sparse professional accents
- Music: happy-beats-business-moves-vol-12 (steady, clean), ~0.32 volume, fade out over last 1.2s
- Music cue guidance: preset read (109.96 BPM). Strong-cue locks: 8.74s (diagram/flow scene), 13.11s (security scene), 17.47s (outro title). Beat grid for sequential reveals: env cards at 3.82 / 4.91 / 6.00 (every other beat); flow nodes at 9.29 / 9.83 / 10.37 / 10.93 / 11.46 (dots — non-text accents OK every beat; labels already on screen).
- Audio-reactive treatment: subtle; bass RMS makes the orange glow behind the outro title and the diagram frame breathe. No visualizer graphics.
- SFX posture: sparse, motion-matched
- Audio-coupled moments: per-char key ticks on `terraform apply`; one click on Enter; soft drops on env cards; soft impact on security lines; bell on outro title.
- Restraint rule: no stacked hits, nothing bright or glitchy.

## Storyboard

### Scene 1 — Hook: terraform apply — 3.27s
Terminal window, path `~/Web_app_infra/environments/prod`. `$ terraform apply` types out; Enter; `Apply complete!` in green, holds ~1s.
Sequential/interaction: yes — typed command + Enter.
Audio intent: intimate, precise. Audio-coupled idea: key ticks per character, click on Enter.
Transition mood: clean → Scene 2

### Scene 2 — Three environments — 5.47s
Headline "Three isolated environments." Three cards deal in one by one (dev, staging, prod): VPC CIDR, instance type, ASG min–max. Prod card gets an orange "deletion protection" tag. Full set holds ~2s.
Sequential/interaction: yes — 3 cards, every-other-beat.
Audio intent: organised momentum. Audio-coupled idea: soft drop per card.
Transition mood: slide → Scene 3

### Scene 3 — The request path — 4.37s (starts on strong cue 8.74)
Left: vertical path Route 53 → WAF → ALB → EC2 Auto Scaling → RDS primary + replica, a red line drawing through, each node lighting. Right: the real architecture diagram in a framed panel, slow push-in. Caption: "WAF filters SQLi, Log4Shell & bad bots first."
Sequential/interaction: yes — node lights.
Audio intent: forward motion. Audio-coupled: one soft impact at the scene start.
Transition mood: clean → Scene 4

### Scene 4 — Nobody SSHes in — 4.36s (starts on strong cue 13.11)
Three big struck lines: "No SSH." "No open ports." "No key pairs." then mono sub-line `aws ssm start-session --target i-…`.
Sequential/interaction: yes — 3 lines (~0.55s apart, all held ≥1.8s).
Audio intent: dry confidence. Soft impact per line.
Transition mood: soft → Scene 5

### Scene 5 — Outro — ~4.0s (title on strong cue 17.47)
"Web_app_infra" huge, "Production-grade AWS, written in Terraform." Stat row: 11 modules · 3 environments · 0 open admin ports. Orange glow breathes with bass.
Audio intent: payoff. Bell on title, music fades.

**Music mood for this video:** polished / steady
**Audio summary:** keyboard-intimate open, steady bed builds through cards and flow, dry hits for the security beat, bell on the title and a clean fade.

## Privacy note
No account IDs, zone IDs, state bucket names, emails, or domain names appear. The diagram is cropped/panned so its footnotes (which list domain names) stay out of frame.
