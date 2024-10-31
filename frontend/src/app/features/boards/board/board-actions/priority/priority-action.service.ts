import { Injectable } from '@angular/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { CachedBoardActionService } from 'core-app/features/boards/board/board-actions/cached-board-action.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';
import { PriorityBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/priority/priority-board-header.component';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class BoardPriorityActionService extends CachedBoardActionService {
  filterName = 'priority';

  text = this.I18n.t('js.boards.board_type.action_type.priority');

  description = this.I18n.t('js.boards.board_type.action_text_priority');

  label = this.I18n.t('js.boards.add_list_modal.labels.priority');

  icon = 'icon-user';

  image = imagePath('board_creation_modal/version.svg');

  localizedName = this.I18n.t('js.work_packages.properties.priority');

  readonly noPriority:any = {
    id: null,
    href: null,
    name: this.I18n.t('js.filter.noneElement'),
  };

  /**
   * Returns the current filter value if any
   * @param query
   * @returns The loaded action reosurce
   */

  getLoadedActionValue(query:QueryResource):Promise<HalResource|undefined> {
    const filter = this.getActionFilter(query);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return filter && filter.operator.id === '!*' ? Promise.resolve(this.noPriority) : super.getLoadedActionValue(query);
  }

  public headerComponent() {
    return PriorityBoardHeaderComponent;
  }

  protected loadUncached = ():Observable<HalResource[]> => {
    const filters = new ApiV3FilterBuilder();
    filters.add('1', '=', true);
    return this.apiV3Service.priorities.filtered(filters).get()
      .pipe(
        map((collection) => collection.elements),
      );
  };
}
