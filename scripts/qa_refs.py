#!/usr/bin/env python3
"""Cross-dataset referential integrity, checked by entity KIND.

scripts/validate_data.py already checks a handful of slots and then gates on a
sample list capped at six entries per key, so a slot with 100 dangling ids
passes if its first six happen to be allow-listed. This checker walks every
id-bearing slot in every dataset, checks each against the universe of the kind
it is supposed to point at, and gates on the full set.

"Resolves to the right kind" is the point. A flower id sitting in
requirements.facilities resolved to nothing; a facility id sitting in
redemption_codes.giftMementoId resolves to nothing either, and the page that
reads it silently drops the link.

Exit code 1 on any unexpected dangling reference.
"""

import collections
import re

from qa_common import (
    Report, load, facility_ids, facility_names_by_id, sample,
)


# Dangling references that are accepted for now, with the reason. Shrink this;
# never grow it to make a run pass.
ALLOWED = {
    # Facilities the wiki references but has no facility page for.
    'customer.requirements.facilities -> facility':
        {'star_rating_board', 'halloween_decorations'},
    # Legacy staff wearable aliases kept so old saves still resolve.
    'staff.wearableMementos[].mementoId -> memento':
        {'sunflower_memento', 'witch_hat', 'crab_memento', 'sleepy_little_bear'},
}


def main():
    rep = Report('qa_refs')

    customers = load('customers.json')
    mementos = load('mementos.json')
    staff = load('staff.json')
    posters = load('posters.json')
    dishes = load('dishes.json')
    letters = load('letters.json')
    flowers = load('flowers.json')
    fish = load('fish.json')
    pets = load('pets.json')
    movies = load('movies.json')
    booths = load('booth_owners.json')
    codes = load('redemption_codes.json')
    income = load('income.json')
    performer_income = load('performer_income.json')

    universe = {
        'customer': {c['id'] for c in customers},
        'memento': {m['id'] for m in mementos},
        'staff': {s['id'] for s in staff},
        'poster': {p['id'] for p in posters},
        'recipe': {d['id'] for d in dishes},
        'recipe_name': {d['name'] for d in dishes},
        'letter': {l['id'] for l in letters},
        'flower': {f['id'] for f in flowers},
        'flower_name': {f['name'] for f in flowers},
        'fish': {f['id'] for f in fish},
        'pet': {p['id'] for p in pets['pets']},
        'pet_room': {r['id'] for r in pets['petRooms']},
        'movie': {m['id'] for m in movies},
        'facility': facility_ids(),
    }

    def check(label, values, kind):
        values = [v for v in values if v is not None]
        bad = {v for v in values if v not in universe[kind]}
        bad -= ALLOWED.get(label, set())
        rep.check(
            not bad,
            f'{label} ({len(values)} refs)',
            f'{len(bad)} unresolved: {sample(bad)}',
        )

    # ------------------------------------------------------------ customers
    rep.section('customers.json')
    check('customer.requirements.customers -> customer',
          [x for c in customers
           for x in (c.get('requirements') or {}).get('customers', [])],
          'customer')
    check('customer.requirements.facilities -> facility',
          [x for c in customers
           for x in (c.get('requirements') or {}).get('facilities', [])],
          'facility')
    check('customer.requirements.flowers -> flower',
          [x for c in customers
           for x in (c.get('requirements') or {}).get('flowers', [])],
          'flower')
    check('customer.requirements.letters -> letter',
          [x for c in customers
           for x in (c.get('requirements') or {}).get('letters', [])],
          'letter')
    # These two slots hold display NAMES, not ids, despite the "Ids" suffix.
    check('customer.requirements.recipes -> recipe NAME',
          [x for c in customers
           for x in (c.get('requirements') or {}).get('recipes', [])],
          'recipe_name')
    check('customer.dishesOrderedIds -> recipe NAME',
          [x for c in customers for x in (c.get('dishesOrderedIds') or [])],
          'recipe_name')
    check('customer.requiredFoodId -> recipe NAME',
          [c.get('requiredFoodId') for c in customers],
          'recipe_name')
    check('customer.mementos[].id -> memento',
          [m['id'] for c in customers for m in (c.get('mementos') or [])],
          'memento')

    # ----------------------------------------------------------- performers
    rep.section('customers.json performer blocks')
    performers = [c for c in customers if c.get('performer')]
    check('performer.fansCustomerIds -> customer',
          [x for c in performers
           for x in (c['performer'].get('fansCustomerIds') or [])],
          'customer')
    check('performer.canInviteThis[].performerId -> customer',
          [x['performerId'] for c in performers
           for x in (c['performer'].get('canInviteThis') or [])],
          'customer')
    check('performer.canBeInvitedBy[].performerId -> customer',
          [x['performerId'] for c in performers
           for x in (c['performer'].get('canBeInvitedBy') or [])],
          'customer')
    check('performer.posterIds -> poster',
          [x for c in performers
           for x in (c['performer'].get('posterIds') or [])],
          'poster')

    # Every performer must exist in performer_income.json and vice versa,
    # because the concert maths reads that file and the page reads the block.
    perf_ids = {c['id'] for c in performers}
    inc_ids = set(performer_income['performers'])
    rep.check(perf_ids == inc_ids,
              'performer blocks match performer_income.json',
              f'only in customers: {sample(perf_ids - inc_ids)}; '
              f'only in performer_income: {sample(inc_ids - perf_ids)}')

    # ------------------------------------------------------------ mementos
    rep.section('mementos.json')
    check('memento.customerId -> customer',
          [m.get('customerId') for m in mementos], 'customer')
    check('memento.equips -> staff',
          [x for m in mementos for x in (m.get('equips') or [])], 'staff')
    check('memento.requirements.customers -> customer',
          [x for m in mementos
           for x in (m.get('requirements') or {}).get('customers', [])],
          'customer')
    check('memento.requirements.serve[].customerId -> customer',
          [x['customerId'] for m in mementos
           for x in (m.get('requirements') or {}).get('serve', [])],
          'customer')
    check('memento.requirements.recipeIds -> recipe',
          [x for m in mementos
           for x in (m.get('requirements') or {}).get('recipeIds', [])],
          'recipe')
    check('memento.requirements.sell[].recipeId -> recipe',
          [x['recipeId'] for m in mementos
           for x in (m.get('requirements') or {}).get('sell', [])],
          'recipe')
    check('memento.requirements.facilities -> facility',
          [x for m in mementos
           for x in (m.get('requirements') or {}).get('facilities', [])],
          'facility')

    # derivedLinks carry their kind in the string ("customer:white_bunny"),
    # so both halves are checkable.
    dangling_links = set()
    unknown_kinds = set()
    link_count = 0
    for m in mementos:
        for raw in (m.get('requirements') or {}).get('derivedLinks', []):
            link_count += 1
            kind, _, value = raw.partition(':')
            if kind not in universe:
                unknown_kinds.add(kind)
            elif value not in universe[kind]:
                dangling_links.add(raw)
    rep.check(not unknown_kinds and not dangling_links,
              f'memento.requirements.derivedLinks ({link_count} refs)',
              f'unknown kinds {sample(unknown_kinds)}; '
              f'dangling {sample(dangling_links)}')

    # --------------------------------------------------------------- staff
    rep.section('staff.json')
    check('staff.wearableMementos[].mementoId -> memento',
          [w['mementoId'] for s in staff for w in s['wearableMementos']],
          'memento')

    # ------------------------------------------------------------- posters
    rep.section('posters.json')
    check('poster.requiredPerformerIds -> customer',
          [x for p in posters for x in p.get('requiredPerformerIds', [])],
          'customer')
    check('poster.requirements.customers -> customer',
          [x for p in posters
           for x in (p.get('requirements') or {}).get('customers', [])],
          'customer')
    check('poster.requirements.facilities -> facility',
          [x for p in posters
           for x in (p.get('requirements') or {}).get('facilities', [])],
          'facility')

    # -------------------------------------------------------- booth owners
    rep.section('booth_owners.json')
    check('booth_owners key -> customer', list(booths), 'customer')
    check('booth.requiredFishIds -> fish',
          [x for b in booths.values() for x in (b.get('requiredFishIds') or [])],
          'fish')
    check('booth.appearanceRatesByFish[].fishId -> fish',
          [r['fishId'] for b in booths.values()
           for r in (b.get('appearanceRatesByFish') or [])],
          'fish')

    # ---------------------------------------------------------------- pets
    rep.section('pets.json')
    check('pets.photoTasks[].pets -> pet',
          [x for t in pets['photoTasks'] for x in (t.get('pets') or [])], 'pet')
    check('pets.photoTasks[].furniture -> facility',
          [x for t in pets['photoTasks'] for x in (t.get('furniture') or [])],
          'facility')
    # pets[].likes mixes staff ids with ids of no known kind.
    likes = [x for p in pets['pets'] for x in (p.get('likes') or [])]
    unknown_likes = {
        x for x in likes
        if not any(x in universe[k]
                   for k in ('staff', 'customer', 'memento', 'pet'))
    }
    rep.check(not unknown_likes,
              f'pets.pets[].likes -> staff|customer|memento|pet ({len(likes)} refs)',
              f'{len(unknown_likes)} of no known kind: {sample(unknown_likes)}')

    # ----------------------------------------------------- letter combos
    rep.section('letters.json')
    # Letter combination slots hold flower NAMES plus a small set of literal
    # sentinels the game itself prints.
    sentinels = {'*', '-', '—', '–', 'Any Combination'}
    slots = [c[s] for l in letters for c in (l.get('combinations') or [])
             for s in ('slot1', 'slot2', 'slot3') if c.get(s)]
    non_flower = {s for s in slots
                  if s not in sentinels and s not in universe['flower_name']}
    # Cans / clovers / seeds are real pot items rather than flowers; the app
    # renders slots as plain text so they are legal, but they must be a closed
    # set or a typo hides in them forever.
    known_items = {'Clover', 'Copper Can', 'Gold Can', 'Iron Can', 'Seed', 'Seeds'}
    rep.check(non_flower <= known_items,
              f'letter.combinations slots ({len(slots)} slots)',
              f'unknown slot values: {sample(non_flower - known_items)}')
    # 'Seed' and 'Seeds' are the same item spelled two ways.
    rep.warn(not ({'Seed', 'Seeds'} <= non_flower),
             'letter.combinations slot spelling is consistent',
             "both 'Seed' and 'Seeds' appear")

    # ---------------------------------------------------- redemption codes
    rep.section('redemption_codes.json')
    fac_ids = universe['facility']
    mem_ids = universe['memento']
    wrong_slot = []
    unresolved_kind = []
    for c in codes:
        kind = c.get('giftKind')
        gift = c.get('giftMementoId')
        if kind == 'unresolved':
            unresolved_kind.append(c['code'])
        if gift is None:
            continue
        if kind == 'memento' and gift not in mem_ids:
            wrong_slot.append((c['code'], gift, 'declared memento, is not one'))
        if kind == 'facility':
            # A facility id parked in a field named giftMementoId. The page
            # only ever looks it up in the memento index, so the link and the
            # checkbox are both lost.
            wrong_slot.append(
                (c['code'], gift, 'facility id stored in giftMementoId'))
    rep.check(not wrong_slot,
              f'redemption code gift refs ({len(codes)} codes)',
              f'{len(wrong_slot)} mis-slotted: {sample(str(w) for w in wrong_slot[:4])}')
    rep.check(not unresolved_kind,
              'redemption codes all have a resolved giftKind',
              f'unresolved: {sample(unresolved_kind)}')

    # -------------------------------------------------------- battle passes
    rep.section('battle_passes/*.json')
    # Mirrors BattlePassReward._parseType. 'movie' was added there on
    # 11 Sep 2026 — the film-fragment rewards used to fall through to text.
    known_reward_types = {
        'facility', 'memento', 'currency', 'rating', 'item', 'movie',
        'gacha_draw', 'promote_free', 'chest', 'text',
    }
    bad_fac, bad_mem, bad_type, bad_flower, bad_fish = set(), set(), set(), set(), set()
    counts = collections.Counter()
    for pass_id in ('deep_sea_ballad', 'fantastical_party',
                    'midsummer_birdsong', 'slumberous_nights'):
        data = load(f'battle_passes/{pass_id}.json')
        for phase in data['phases']:
            for tier in phase['tiers']:
                rewards = (tier.get('normalRewards') or []) + \
                          (tier.get('superRewards') or [])
                for r in rewards:
                    counts[r['type']] += 1
                    if r['type'] not in known_reward_types:
                        bad_type.add(r['type'])
                    if r['type'] == 'facility' and r.get('id') not in fac_ids:
                        bad_fac.add(r.get('id'))
                    if r['type'] == 'memento' and r.get('id') not in mem_ids:
                        bad_mem.add(r.get('id'))
                    if r['type'] == 'item' and r.get('itemType') == 'flower' \
                            and r.get('id') not in universe['flower']:
                        bad_flower.add(r.get('id'))
                    if r['type'] == 'item' and r.get('itemType') == 'fish' \
                            and r.get('id') not in universe['fish']:
                        bad_fish.add(r.get('id'))
    rep.check(not bad_type,
              'battle pass reward types are all parseable by '
              'BattlePassReward._parseType',
              f'unhandled types {sample(bad_type)} — these fall through to '
              f'BattlePassRewardType.text and render as "Info"')
    rep.check(not bad_fac,
              f'battle pass facility rewards -> facility '
              f'({counts["facility"]} refs)',
              f'{len(bad_fac)} unresolved: {sample(bad_fac)}')
    rep.check(not bad_mem,
              f'battle pass memento rewards -> memento '
              f'({counts["memento"]} refs)',
              f'{len(bad_mem)} unresolved: {sample(bad_mem)}')
    rep.check(not bad_flower,
              'battle pass flower item rewards -> flower',
              f'unresolved: {sample(bad_flower)}')
    rep.check(not bad_fish,
              'battle pass fish item rewards -> fish',
              f'unresolved: {sample(bad_fish)}')

    # -------------------------------------------------------------- income
    rep.section('income.json')
    check('income.facilities key -> facility', list(income['facilities']),
          'facility')
    declared = set(income['channels'])
    used = {e['channel'] for rows in income['facilities'].values() for e in rows}
    rep.check(used <= declared, 'income channels are all declared',
              f'undeclared: {sample(used - declared)}')
    rep.check(declared <= used, 'income channels are all used',
              f'declared but unused: {sample(declared - used)}')
    # Every row must carry a quantity, or it silently contributes zero.
    no_qty = [(fid, e['channel']) for fid, rows in income['facilities'].items()
              for e in rows
              if not ({'amount', 'min', 'max', 'percent'} & set(e))]
    rep.check(not no_qty, 'every income row carries a quantity',
              sample(str(x) for x in no_qty[:6]))
    # A per-N-seconds row without its period reads as zero per hour.
    no_secs = [fid for fid, rows in income['facilities'].items()
               for e in rows if e['channel'] == 'codPerSeconds'
               and not e.get('seconds')]
    rep.check(not no_secs, 'every codPerSeconds row carries its period',
              sample(no_secs))

    rep.finish()


if __name__ == '__main__':
    main()
