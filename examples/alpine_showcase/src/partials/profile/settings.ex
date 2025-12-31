defmodule AlpineShowcase.Partials.Profile.Settings do
  use Nex.Partial

  def profile_settings(assigns) do
    ~H"""
    <!-- Initialize local state: bio and isDirty -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title mb-4">Edit Profile</h2>
        <form 
          x-data="{ 
            bio: 'Original bio content...', 
            originalBio: 'Original bio content...',
            get charsCount() { return this.bio.length; },
            get isDirty() { return this.bio !== this.originalBio; }
          }"
          hx-put="/update_settings"
          hx-swap="none"
          x-on:htmx:after-request="originalBio = bio; $dispatch('show-toast', 'Settings saved successfully!')"
        >
          <div class="form-control">
            <label class="label">
              <span class="label-text">Your Bio</span>
              <!-- Real-time character count -->
              <span class="label-text-alt" x-bind:class="{ 'text-error': charsCount > 100 }">
                <span x-text="charsCount"></span>/100
              </span>
            </label>
            
            <!-- x-model binds input to state -->
            <textarea 
              name="bio" 
              class="textarea textarea-bordered h-24" 
              x-model="bio"
              maxlength="100"
            ></textarea>
          </div>

          <!-- Skills Tags (Tags Input) - Demonstrates x-for and client-side array manipulation -->
          <div class="form-control mt-4" x-data="{ newTag: '', tags: ['Elixir', 'Alpine'] }">
             <label class="label"><span class="label-text">Skills (Press Enter to add)</span></label>
             <div class="flex gap-2 mb-2">
                <input 
                  type="text" 
                  class="input input-bordered w-full max-w-xs"
                  placeholder="Add a skill..."
                  x-model="newTag"
                  x-on:keydown.enter.prevent="if(newTag.trim()) { tags.push(newTag.trim()); newTag = ''; }"
                />
             </div>
             <div class="flex flex-wrap gap-2">
                <template x-for="(tag, index) in tags" x-bind:key="index">
                   <div class="badge badge-info gap-2 p-3">
                      <span x-text="tag"></span>
                      <button type="button" x-on:click="tags.splice(index, 1)" class="btn btn-xs btn-ghost btn-circle">x</button>
                      <!-- Hidden input for submitting data -->
                      <input type="hidden" name="skills[]" x-bind:value="tag" />
                   </div>
                </template>
             </div>
          </div>

          <div class="card-actions justify-end mt-6">
            <!-- Save button is disabled if content is unchanged -->
            <button 
              type="submit" 
              class="btn btn-primary"
              x-bind:disabled="!isDirty"
            >
              Save Changes
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
