module global
   integer, parameter :: MAX_WORD_LENGTH = 32
   integer, parameter :: MIN_WORD_LENGTH = 3
   character(len=MAX_WORD_LENGTH), allocatable :: dictionary(:)
   character(len=MAX_WORD_LENGTH), allocatable :: found_words(:)
   character, allocatable :: letter_grid(:, :)

   integer :: grid_size, word_count
end module global

program Boggle
   use, intrinsic :: iso_fortran_env, idp => int64
   use global
   implicit none
   character(len=256) :: dictionary_file, params_file, output_file
   character(len=MAX_WORD_LENGTH) :: tword
   character(len=MAX_WORD_LENGTH), allocatable :: twords(:)
   integer(idp) :: outputios, outputunit
   integer(idp) :: found_count, tcount, merge_position, start_row, start_column, start_index, local_depth
   integer(idp) ::  i
   logical, allocatable :: tvisited(:, :)
   dictionary_file = 'sowpods.txt'
   if (command_argument_count() >= 1) then
      call get_command_argument(1, dictionary_file)
   end if
   call load_dictionary(dictionary_file)
   ! For parameters, default to params.txt, otherwise load user-supplied file params_file
   params_file = 'params.txt'
   if (command_argument_count() >= 2) then
      call get_command_argument(2, params_file)
   end if
   call read_params(params_file)
   allocate (found_words(size(dictionary)*10))
   found_count = 0
   !$omp parallel private(tvisited, tword, twords, tcount, merge_position, start_row, start_column)
   allocate (tvisited(grid_size, grid_size))
   ! This seems like a reasonably high cap
   allocate (twords(200))
   tvisited = .false.
   tword = " "
   tcount = 0

   local_depth = 1
   ! Do word search
   !$omp do schedule(dynamic)
   do start_index = 1, grid_size*grid_size
      start_row = (start_index - 1)/grid_size + 1
      start_column = mod(start_index - 1, grid_size) + 1
      call word_search(start_row, start_column, local_depth, tword, &
                       tvisited, twords, tcount)
   end do
   !$omp end do

   ! Search done, merge words and remove duplicates
   !$omp critical (merge_results)
   do merge_position = 1, tcount
      call append_words_local(found_words, found_count, twords(merge_position))
   end do
   !$omp end critical (merge_results)
   deallocate (tvisited)
   deallocate (twords)
   !$omp end parallel
   call sort_found_words(found_words, found_count)
   call remove_duplicates(found_words, found_count)
   print '(/1x, A, I10, A)', 'Found ', found_count, ' word(s):'
   output_file = "found.txt"
   open (newunit=outputunit, file=output_file, status='replace', action='write', iostat=outputios)
   if (outputios /= 0) stop "Error writing to output file"
   do i = 1, found_count
      write (outputunit, '(A)') trim(found_words(i))
   end do
   close (outputunit)
contains
   ! -------------------------------------------------------------------
   ! subroutine word_search
   ! -------------------------------------------------------------------
  !!  NAME
  !!   read_params - finds words in a letter grid
  !!  USAGE
  !!    read_params(filename, grid_size, letter_grid)
  !!  PURPOSE
  !!     Uses a recursive depth-first search to find words.
  !!     Given a starting letter, it extends it by one letter at a time
  !!        via its neighbours
  !!    It searches its neighbours, and compares current_word to the dictionary
  !!    If the current string of letters cannot be matched to a substring in the
  !!        dictionary, it terminates.
  !!    Example: no words begin with 'qx', so the DFS immediately terminates on all branches
  !!    Example: 'ca', many words begin with 'ca', e.g. 'can', 'cat', 'cant' etc, so the DFS
  !!              continues
  !!  INPUTS
  !!   character(len=256), intent(in) :: row, column, depth - holds information
  !!      about the current letter and how far the search has gone
  !!  character(len=MAX_WORD_LENGTH), intent(inout) :: current_word
  !!  logical, intent(inout) :: visited(:,:) - whether a cell has been visited
  !!      the current search, as we cannot double back
  !!  character(len=MAX_WORD_LENGTH), intent(inout) :: local_words(:)
  !!    A thread's store of words it has found
  !!  USES
  !!    intrinsic, iso_fortran_env, idp => int64
  !!    global, only: dictionary, word_count, MAX_WORD_LENGTH, MIN_WORD_LENGTH
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   21/11/2026
  !!  MODIFICATION HISTORY
  !!   23/11/2026 chpxu: iso_fortran_env int64
   recursive subroutine word_search(row, column, depth, &
                                    current_word, visited, local_words, local_count)
      
      use, intrinsic :: iso_fortran_env, idp => int64
      use global, only: dictionary, word_count, MAX_WORD_LENGTH, MIN_WORD_LENGTH
      implicit none
      integer(idp), intent(in) :: row, column, depth
      character(len=MAX_WORD_LENGTH), intent(inout) :: current_word
      character(len=MAX_WORD_LENGTH), allocatable, intent(inout) :: local_words(:)
      logical, intent(inout) :: visited(:, :)
      integer(idp), intent(inout) :: local_count

      ! Local variables
      integer(idp) :: row_offset, column_offset, next_row, next_column, first_match
      character(len=MAX_WORD_LENGTH) :: prefix

      current_word(depth:depth) = letter_grid(row, column)
      prefix = current_word(1:depth)
      first_match = lower_bound(prefix)
      !print *, first_match, depth, prefix
      if (first_match > word_count) return
      if (dictionary(first_match) (1:depth) /= prefix(1:depth)) return

      visited(row, column) = .true.
      if (depth >= MIN_WORD_LENGTH .and. dictionary(first_match) == prefix) then
         call append_words_local(local_words, local_count, prefix)
      end if ! word found then append

      if (depth < MAX_WORD_LENGTH) then
         do row_offset = -1, 1
            do column_offset = -1, 1
               if (row_offset == 0 .and. column_offset == 0) cycle
               next_row = row + row_offset
               next_column = column + column_offset
               ! If out-of-bounds or visited then skip
               if (next_row < 1 .or. next_row > grid_size) cycle
               if (next_column < 1 .or. next_column > grid_size) cycle
               if (visited(next_row, next_column)) cycle
               call word_search(next_row, next_column, depth + 1, current_word, &
                                visited, local_words, local_count)
            end do ! column_offset
         end do ! row_offset
      end if ! depth <MAX_WORD_LENGTH
      visited(row, column) = .false.
      current_word(depth:depth) = ""
   end subroutine word_search
   ! -------------------------------------------------------------------
   ! subroutine append_words_local
   ! -------------------------------------------------------------------
  !!  NAME
  !!    append_words_local
  !!  USAGE
  !!    append_words_local(words, local_word_count, candidate)
  !!  PURPOSE
  !!    Appends word 'candidate' to array 'words' and updates local_word_count.
  !!    This is called per-thread.
  !!  INPUTS
  !!    character(len=MAX_WORD_LENGTH), allocatable, intent(inout) :: words(:)
  !!        Array of words (thread private copy)
  !!    integer, intent(inout) :: local_word_count
  !!         Number of words (thread private copy)
  !!    character(len=*), intent(in) :: candidate
  !!        Word to add to array
  !!  USES
  !!    iso_fortran_env, idp => int64
  !!    global, only: MAX_WORD_LENGTH
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   22/11/2026
  !!  MODIFICATION HISTORY
  !!   23/11/2026 chpxu: iso_fortran_env int64
   subroutine append_words_local(words, local_word_count, candidate)
      
      use, intrinsic :: iso_fortran_env, idp => int64
      use global, only: MAX_WORD_LENGTH
      implicit none
      character(len=MAX_WORD_LENGTH), allocatable, intent(inout) :: words(:)
      integer(idp), intent(inout) :: local_word_count
      character(len=*), intent(in) :: candidate

      ! Local variables
      character(len=MAX_WORD_LENGTH), allocatable :: resized_word_list(:)
      if (local_word_count == size(words)) then
         allocate (resized_word_list(2*size(words)))
         resized_word_list(1:local_word_count) = words
         call move_alloc(resized_word_list, words)
      end if
      local_word_count = local_word_count + 1
      words(local_word_count) = candidate
   end subroutine append_words_local

   ! -------------------------------------------------------------------
   ! function lower_bound
   ! -------------------------------------------------------------------
  !!  NAME
  !!    lower_bound
  !!  USAGE
  !!    lower_bound(string)
  !!  PURPOSE
  !!    Checks whether common substring relative to a dictionary word
  !!  INPUTS
  !!    character(len=*), intent(in) :: string
  !!         String to compare (thread private copy)
  !!  USES
  !!    iso_fortran_env, idp => int64
  !!    global, only: dictionary
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   22/11/2026
  !!  MODIFICATION HISTORY
  !!   23/11/2026 chpxu: iso_fortran_env int64
   integer(idp) function lower_bound(string)
      use, intrinsic :: iso_fortran_env, idp => int64
      use global, only: dictionary
      implicit none
      character(len=*), intent(in) :: string
      integer(idp) :: low, mid, high

      low = 1
      high = word_count + 1
      do while (low < high)
         mid = (low + high)/2
         if (dictionary(mid) < string) then
            low = mid + 1
         else
            high = mid
         end if

      end do
      lower_bound = low
   end function lower_bound

   ! -------------------------------------------------------------------
   ! subroutine load_dictionary
   ! -------------------------------------------------------------------
  !!  NAME
  !!   load_dictionary - Read in a file containing words
  !!  USAGE
  !!    load_dictionary(filename)
  !!  PURPOSE
  !!    Loads in a file to use as a dictionary. The file should be letters-only,
  !!      and be individual words on a newline
  !!  INPUTS
  !!  character(len=*), intent(in) :: filename
  !!    Path to file containing dictionary
  !!  USES
  !!    global, only: dictionary, word_count
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   21/11/2026
  !!  MODIFICATION HISTORY
   subroutine load_dictionary(filename)

      use, intrinsic :: iso_fortran_env, idp => int64
      use global, only: dictionary, word_count
      implicit none
      character(len=*), intent(in) :: filename
      character(len=256) :: raw_word, trimmed
      integer(idp) :: iounit, ios
      integer(idp) :: word_length, line_count
      logical :: alpha

      open (newunit=iounit, file=filename, status="old", action="read", iostat=ios)
      if (ios /= 0) then
         print '(/2x, 2A)', 'Cannot open dictionary file: ', filename
         call abort
      end if
      ! Read file twice: once to set word_count and second to store words
      ! Dictionary file assumed one word per line, letters only
      word_count = 0
      line_count = 0
      do
         read (iounit, *, iostat=ios) raw_word
         if (ios /= 0) exit
         line_count = line_count + 1
      end do
      rewind (iounit)
      raw_word = ""
      if (allocated(dictionary)) deallocate (dictionary)
      allocate (dictionary(line_count))
      do
         read (iounit, *, iostat=ios) raw_word
         if (ios /= 0) exit
         trimmed = to_lower(adjustl(raw_word))
         word_length = len_trim(trimmed)
         ! In Boggle, normally 3 letter words is the minimum
         if (word_length > MAX_WORD_LENGTH .or. word_length < MIN_WORD_LENGTH) cycle
         word_count = word_count + 1
         alpha = verify(trimmed(1:word_length), &
                        'abcdefghijklmnopqrstuvwxyz') == 0
         ! If this word for some reason has non-letters, skip,
         !  and what dicitionary did you get this from??
         if (.not. alpha) cycle
         dictionary(word_count) = trimmed(1:word_length)
      end do
      close (iounit)
   end subroutine load_dictionary

   ! -------------------------------------------------------------------
   ! function to_lower
   ! -------------------------------------------------------------------
  !!  NAME
  !!   to_lower - lowercase a string
  !!  USAGE
  !!    to_lower(text)
  !!  PURPOSE
  !!    Turns all characters of a string lowercase
  !!  INPUTS
  !!  character(len=*), intent(in) :: text
  !!    String to lowercase
  !!  USES
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   21/11/2026
  !!  MODIFICATION HISTORY
   function to_lower(text) result(lowered)
      use, intrinsic :: iso_fortran_env, idp => int64
      implicit none
      character(len=*), intent(in) :: text
      character(len=len(text)) :: lowered
      integer(idp) :: char_position

      lowered = text
      do char_position = 1, len(text)
         if (lowered(char_position:char_position) >= 'A' .and. &
             lowered(char_position:char_position) <= 'Z') then
            lowered(char_position:char_position) = &
               achar(iachar(lowered(char_position:char_position)) + 32)
         end if
      end do
   end function to_lower

   ! -------------------------------------------------------------------
   ! subroutine read_params
   ! -------------------------------------------------------------------
  !!  NAME
  !!   read_params - reads Boggle parameters
  !!  USAGE
  !!    read_params(filename, grid_size, letter_grid)
  !!  PURPOSE
  !!   Reads a file which contains the letter parameters needed to run Boggle.
  !!   The file is structured as so:
  !!    <int>  ! grid_size
  !!    a b c d  ! grid_size entries
  !!    a b c d  ! grid_size entries
  !!    a b c d  ! grid_size entries
  !!    a b c d  ! grid_size entries
  !!    where a b c d are letters of the alphabet. The letters MUST be space-separated.
  !!    Capitals and non-capitals are allowed, though all will be converted to lowercase
  !!  INPUTS
  !!   character(len=256), intent(in) :: filename
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   21/11/2026
  !!  MODIFICATION HISTORY
  !!   23/11/2026 chpxu: Correctly interpret grid_size and close iounit; 
  !       iso_fortran_env
   subroutine read_params(filename)
      use, intrinsic :: iso_fortran_env, idp => int64 
      use global, only: letter_grid, grid_size
      implicit none
      character(len=256), intent(in) :: filename

      integer(idp) :: iounit, ios
      integer(idp) :: row_index, column_index
      ! This iounit is params.txt
      ! First number: grid_size, then letter grid
      open (newunit=iounit, file=filename, status="old", action="read", iostat=ios)
      if (ios /= 0) call abort
      read (iounit, *, iostat=ios) grid_size

      if(grid_size <= 1) stop "Grid size cannot be 1 or smaller"
      if (allocated(letter_grid)) deallocate (letter_grid)
      allocate (letter_grid(grid_size, grid_size))

      do row_index = 1, grid_size
         read (iounit, *, iostat=ios) letter_grid(row_index, :)
         if (ios /= 0) stop 'Grid row supplied shorter than grid_size.'
      end do ! row_index, initially fill letter_grid
      do row_index = 1, grid_size
         do column_index = 1, grid_size
            letter_grid(row_index, column_index) =  to_lower(letter_grid(row_index, column_index))
          end do
      end do ! end do to_lower
      close(iounit)
   end subroutine read_params
   ! -------------------------------------------------------------------
   ! subroutine sort_found_words
   ! -------------------------------------------------------------------
  !!  NAME
  !!   sort_found_words
  !!  USAGE
  !!    sort_found_words(words, found_word_count)
  !!  PURPOSE
  !!   Sorts array of string alphabetically using binary search
  !!  INPUTS
  !!   character(len=*), intent(inout) :: words(:)
  !!      Array of words to sort alphabetically
  !!   integer, intent(in) :: found_word_count
  !!      Total number of words found (including duplicates)
  !!  USES 
  !!   global, only: word_count - total found word count
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   22/11/2026
  !!  MODIFICATION HISTORY
   subroutine sort_found_words(words, found_word_count)
      use, intrinsic :: iso_fortran_env, idp => int64
      use global, only: word_count
      implicit none
      character(len=*), intent(inout) :: words(:)
      integer(idp), intent(in) :: found_word_count

      ! Local variables
      character(len=MAX_WORD_LENGTH) :: temp_word
      integer(idp) :: gap, inner_position, outer_position

      gap = found_word_count/2
      do while (gap > 0)
         do outer_position = gap + 1, found_word_count
            temp_word = words(outer_position)
            inner_position = outer_position
            do while (inner_position > gap)
               if (words(inner_position - gap) <= temp_word) exit
               words(inner_position) = words(inner_position - gap)
               inner_position = inner_position - gap
            end do
            words(inner_position) = temp_word
         end do
         gap = gap/2
      end do
   end subroutine sort_found_words
   ! -------------------------------------------------------------------
   ! subroutine remove_duplicates
   ! -------------------------------------------------------------------
  !!  NAME
  !!   remove_duplicates
  !!  USAGE
  !!    remove_duplicates(words, word_count)
  !!  PURPOSE
  !!    Remove duplicate string entries from an array
  !!  INPUTS
  !!   character(len=*), intent(inout) :: words(:)
  !!      Array of words to dedupe
  !!   character(len=*), intent(inout) :: word_count
  !!      Number of (unique) words, which will be mutated from input
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   22/11/2026
  !!  MODIFICATION HISTORY
  !!   23/11/2026 chpxu: Return if word_count is <2
   subroutine remove_duplicates(words, word_count)
      use, intrinsic :: iso_fortran_env, idp => int64
      implicit none
      character(len=*), intent(inout) :: words(:)
      integer(idp), intent(inout) :: word_count

      ! Local variables
      integer(idp) :: position, nunique
      if (word_count < 2) return
      nunique = 1
      do position = 1, word_count
         if (words(position) /= words(nunique)) then
            nunique = nunique + 1
            words(nunique) = words(position)
         end if
      end do
      word_count = nunique
   end subroutine remove_duplicates
end program Boggle
