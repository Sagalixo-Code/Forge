const ProfileTypes = {}

export type ProfileManager<T> = {
    Load: (self: ProfileManager<T>, Player: Player) -> {T},
    Get: (self: ProfileManager<T>, Player: Player) -> {T},
    Release: (self: ProfileManager<T>, Player: Player) -> nil
}

return ProfileTypes