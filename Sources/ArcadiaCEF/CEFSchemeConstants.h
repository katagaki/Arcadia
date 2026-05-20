#pragma once

// Custom scheme used to replay offline snapshots. Registered as standard +
// secure so cached pages get a trustworthy origin. http/https and this scheme
// are the only schemes Arcadia ever allows to navigate.
#define ARCADIA_CACHE_SCHEME "arcadia-cache"
