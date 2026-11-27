! -----------------------------------------------------------------------------
! $Id$
! -----------------------------------------------------------------------------
! read_module
! -----------------------------------------------------------------------------
!!  NAME
!!   read_module - contains all routines needed to read and analyse Boggle data 
!!  PURPOSE
!!   Processes dictionaries and Boggle parameters 
!!  USES
!!   global 
!!  AUTHOR
!!   chpxu
!!  CREATION DATE
!!   27/11/2026
!!  MODIFICATION HISTORY
module read_module
   
  use global, only: letter_grid, grid_size, tile_len, idp, MAX_WORD_LENGTH, &
    dictionary, word_count, error_unit
  implicit none
  private 
  public :: load_dictionary, read_params
  contains 
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
  !!   27/11/2026 chpxu: move to read_module.f90
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
  !!    <int>  ! max letters per tile
  !!    a b c d  ! grid_size entries
  !!    a b c d  ! grid_size entries
  !!    a b c d  ! grid_size entries
  !!    a b c d  ! grid_size entries
  !!    where a b c d are letters of the alphabet. The letters MUST be space-separated. Any tile may contain multiple letters, so
  !!    a b qu d
  !!    a b c d
  !!    a b c d
  !!    is b c d
  !!    is also a valid 4x4 grid
  !!    Capitals and non-capitals are allowed, though all will be converted to lowercase
  !!  INPUTS
  !!   character(len=256), intent(in) :: filename
  !!  AUTHOR
  !!   chpxu
  !!  CREATION DATE
  !!   21/11/2026
  !!  MODIFICATION HISTORY
  !!   23/11/2026 chpxu: Correctly interpret grid_size and close iounit;
  !!   24/11/2026 chpxu: Allow multi-letter tiles and introduce error_unit
  !!   27/11/2026 chpxu: move to read_module.f90
   subroutine read_params(filename)
      implicit none
      character(len=256), intent(in) :: filename

      integer(idp) :: iounit, ios
      integer(idp) :: row_index, column_index
      ! This iounit is params.txt
      ! First number: grid_size, then letter grid
      open (newunit=iounit, file=filename, status="old", action="read", iostat=ios)
      if (ios /= 0) call abort
      read (iounit, *, iostat=ios) grid_size
      if (grid_size <= 1) stop "Grid size cannot be 1 or smaller"
      if (allocated(letter_grid)) deallocate (letter_grid)
      read (iounit, *, iostat=ios) tile_len
      if (tile_len < 1) then
         write (error_unit, *) "read_params: minimum 1 letter per tile"
      end if ! if not min 1 letter per tile
      if (tile_len > MAX_WORD_LENGTH - 1) then
         write (error_unit, '(A,I10)') "read_params: maximum number of letters per tile must be less than ", MAX_WORD_LENGTH - 1
         stop 1
      end if ! if tile_len per word too long

      allocate (character(len=tile_len) :: letter_grid(grid_size, grid_size))
      do row_index = 1, grid_size
         read (iounit, *, iostat=ios) letter_grid(row_index, :)
         if (ios /= 0) then
            write (error_unit, *) 'Grid row supplied shorter than grid_size.'
            stop 1
         end if ! if not enough letters
      end do ! row_index, initially fill letter_grid
      do row_index = 1, grid_size
         do column_index = 1, grid_size
            letter_grid(row_index, column_index) = to_lower(letter_grid(row_index, column_index))
         end do
      end do ! end do to_lower
      close (iounit)
   end subroutine read_params
  end module read_module
